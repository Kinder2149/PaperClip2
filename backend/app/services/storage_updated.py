import os
import uuid
import shutil
from fastapi import UploadFile
from pathlib import Path
import boto3
from botocore.exceptions import ClientError
from dotenv import load_dotenv
import mimetypes
import json

# Chargement des variables d'environnement
load_dotenv()

# Configuration du stockage
STORAGE_TYPE = os.getenv("STORAGE_TYPE", "local")  # local ou s3
LOCAL_STORAGE_PATH = os.getenv("LOCAL_STORAGE_PATH", "./storage")
S3_BUCKET = os.getenv("S3_BUCKET", "paperclip2-storage")
S3_REGION = os.getenv("S3_REGION", "eu-west-3")
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY")

# Créer le répertoire de stockage local s'il n'existe pas
if STORAGE_TYPE == "local":
    os.makedirs(LOCAL_STORAGE_PATH, exist_ok=True)
    os.makedirs(os.path.join(LOCAL_STORAGE_PATH, "profiles"), exist_ok=True)
    os.makedirs(os.path.join(LOCAL_STORAGE_PATH, "saves"), exist_ok=True)

# Initialiser le client S3 si nécessaire
s3_client = None
if STORAGE_TYPE == "s3" and AWS_ACCESS_KEY and AWS_SECRET_KEY:
    s3_client = boto3.client(
        's3',
        region_name=S3_REGION,
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY
    )


class StorageService:
    """
    Service de gestion du stockage des fichiers
    """
    
    async def upload_file(self, file: UploadFile, user_id: str, path: str = None) -> tuple:
        """
        Télécharge un fichier vers le stockage (local ou S3)
        
        Args:
            file: Le fichier à télécharger
            user_id: L'ID de l'utilisateur
            path: Le chemin de destination dans le stockage (optionnel)
            
        Returns:
            Un tuple (file_id, file_url) contenant l'ID et l'URL du fichier téléchargé
        """
        # Générer un nom de fichier unique et un ID de fichier
        file_id = str(uuid.uuid4())
        filename = f"{file_id}_{file.filename}"
        
        # Utiliser le chemin spécifié ou un dossier par défaut
        folder_path = path if path else "files"
        
        # Construire le chemin complet
        full_path = f"{user_id}/{folder_path}/{filename}"
        
        if STORAGE_TYPE == "local":
            # Stockage local
            local_path = os.path.join(LOCAL_STORAGE_PATH, full_path)
            
            # Créer le répertoire parent s'il n'existe pas
            os.makedirs(os.path.dirname(local_path), exist_ok=True)
            
            # Enregistrer le fichier
            with open(local_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            
            # Retourner l'ID et l'URL relative
            return file_id, f"/api/storage/download/{full_path}"
        
        elif STORAGE_TYPE == "s3" and s3_client:
            # Stockage S3
            content_type = file.content_type or mimetypes.guess_type(file.filename)[0]
            
            # Télécharger vers S3
            s3_client.upload_fileobj(
                file.file,
                S3_BUCKET,
                full_path,
                ExtraArgs={"ContentType": content_type}
            )
            
            # Retourner l'ID et l'URL S3
            return file_id, f"https://{S3_BUCKET}.s3.{S3_REGION}.amazonaws.com/{full_path}"
        
        else:
            raise ValueError("Configuration de stockage invalide")
    
    async def upload_profile_image(self, file: UploadFile, user_id: str) -> tuple:
        """
        Télécharge une image de profil
        
        Args:
            file: L'image à télécharger
            user_id: L'ID de l'utilisateur
            
        Returns:
            Un tuple (file_id, file_url) contenant l'ID et l'URL de l'image téléchargée
        """
        return await self.upload_file(file, user_id, "profiles")
    
    async def download_file(self, path: str, user_id: str):
        """
        Télécharge un fichier depuis le stockage
        
        Args:
            path: Le chemin du fichier dans le stockage
            user_id: L'ID de l'utilisateur
            
        Returns:
            Le contenu du fichier et son type MIME
        """
        # Construire le chemin complet
        full_path = f"{user_id}/{path}"
        
        if STORAGE_TYPE == "local":
            # Stockage local
            local_path = os.path.join(LOCAL_STORAGE_PATH, full_path)
            
            if not os.path.exists(local_path):
                raise FileNotFoundError(f"Fichier non trouvé: {local_path}")
            
            # Lire le fichier
            with open(local_path, "rb") as file:
                content = file.read()
            
            # Déterminer le type MIME
            content_type = mimetypes.guess_type(local_path)[0] or "application/octet-stream"
            
            return content, content_type
        
        elif STORAGE_TYPE == "s3" and s3_client:
            # Stockage S3
            try:
                response = s3_client.get_object(Bucket=S3_BUCKET, Key=full_path)
                content = response['Body'].read()
                content_type = response.get('ContentType', 'application/octet-stream')
                
                return content, content_type
            
            except ClientError as e:
                if e.response['Error']['Code'] == 'NoSuchKey':
                    raise FileNotFoundError(f"Fichier non trouvé: {full_path}")
                else:
                    raise
        
        else:
            raise ValueError("Configuration de stockage invalide")
    
    async def delete_file(self, path: str, user_id: str):
        """
        Supprime un fichier du stockage
        
        Args:
            path: Le chemin du fichier dans le stockage
            user_id: L'ID de l'utilisateur
        """
        # Construire le chemin complet
        full_path = f"{user_id}/{path}"
        
        if STORAGE_TYPE == "local":
            # Stockage local
            local_path = os.path.join(LOCAL_STORAGE_PATH, full_path)
            
            if not os.path.exists(local_path):
                raise FileNotFoundError(f"Fichier non trouvé: {local_path}")
            
            # Supprimer le fichier
            os.remove(local_path)
        
        elif STORAGE_TYPE == "s3" and s3_client:
            # Stockage S3
            try:
                s3_client.delete_object(Bucket=S3_BUCKET, Key=full_path)
            
            except ClientError as e:
                if e.response['Error']['Code'] == 'NoSuchKey':
                    raise FileNotFoundError(f"Fichier non trouvé: {full_path}")
                else:
                    raise
        
        else:
            raise ValueError("Configuration de stockage invalide")
    
    def save_game_data(self, user_id: str, save_id: str, data: str):
        """
        Sauvegarde les données de jeu dans un fichier
        
        Args:
            user_id: L'ID de l'utilisateur
            save_id: L'ID de la sauvegarde
            data: Les données JSON de la sauvegarde
        """
        path = f"{user_id}/saves/{save_id}.json"
        
        if STORAGE_TYPE == "local":
            # Stockage local
            local_path = os.path.join(LOCAL_STORAGE_PATH, path)
            
            # Créer le répertoire parent s'il n'existe pas
            os.makedirs(os.path.dirname(local_path), exist_ok=True)
            
            # Enregistrer les données
            with open(local_path, "w") as file:
                file.write(data)
        
        elif STORAGE_TYPE == "s3" and s3_client:
            # Stockage S3
            s3_client.put_object(
                Bucket=S3_BUCKET,
                Key=path,
                Body=data,
                ContentType="application/json"
            )
        
        else:
            raise ValueError("Configuration de stockage invalide")
    
    def get_game_data(self, user_id: str, save_id: str) -> str:
        """
        Récupère les données de jeu depuis un fichier
        
        Args:
            user_id: L'ID de l'utilisateur
            save_id: L'ID de la sauvegarde
            
        Returns:
            Les données JSON de la sauvegarde
        """
        path = f"{user_id}/saves/{save_id}.json"
        
        if STORAGE_TYPE == "local":
            # Stockage local
            local_path = os.path.join(LOCAL_STORAGE_PATH, path)
            
            if not os.path.exists(local_path):
                return None
            
            # Lire les données
            with open(local_path, "r") as file:
                return file.read()
        
        elif STORAGE_TYPE == "s3" and s3_client:
            # Stockage S3
            try:
                response = s3_client.get_object(Bucket=S3_BUCKET, Key=path)
                return response['Body'].read().decode('utf-8')
            
            except ClientError as e:
                if e.response['Error']['Code'] == 'NoSuchKey':
                    return None
                else:
                    raise
        
        else:
            raise ValueError("Configuration de stockage invalide")
    
    def delete_game_data(self, user_id: str, save_id: str):
        """
        Supprime les données de jeu
        
        Args:
            user_id: L'ID de l'utilisateur
            save_id: L'ID de la sauvegarde
        """
        path = f"{user_id}/saves/{save_id}.json"
        
        if STORAGE_TYPE == "local":
            # Stockage local
            local_path = os.path.join(LOCAL_STORAGE_PATH, path)
            
            if os.path.exists(local_path):
                os.remove(local_path)
        
        elif STORAGE_TYPE == "s3" and s3_client:
            # Stockage S3
            try:
                s3_client.delete_object(Bucket=S3_BUCKET, Key=path)
            except:
                pass  # Ignorer les erreurs si le fichier n'existe pas
        
        else:
            raise ValueError("Configuration de stockage invalide")
            
    def get_storage_type(self) -> str:
        """
        Retourne le type de stockage utilisé
        
        Returns:
            Le type de stockage ("local" ou "s3")
        """
        return STORAGE_TYPE
    
    def get_usage_info(self, user_id: str) -> dict:
        """
        Retourne les informations d'utilisation du stockage pour un utilisateur
        
        Args:
            user_id: L'ID de l'utilisateur
            
        Returns:
            Un dictionnaire contenant les informations d'utilisation
        """
        total_size = 0
        file_count = 0
        save_count = 0
        
        try:
            if STORAGE_TYPE == "local":
                # Stockage local - Calcul de la taille totale des fichiers de l'utilisateur
                user_dir = os.path.join(LOCAL_STORAGE_PATH, user_id)
                
                if os.path.exists(user_dir):
                    # Parcourir tous les fichiers de l'utilisateur
                    for root, _, files in os.walk(user_dir):
                        for file in files:
                            file_path = os.path.join(root, file)
                            total_size += os.path.getsize(file_path)
                            file_count += 1
                            
                            # Compter les sauvegardes
                            if root.endswith('/saves') and file.endswith('.json'):
                                save_count += 1
            
            elif STORAGE_TYPE == "s3" and s3_client:
                # Stockage S3 - Liste des objets et calcul de la taille
                paginator = s3_client.get_paginator('list_objects_v2')
                for page in paginator.paginate(Bucket=S3_BUCKET, Prefix=f"{user_id}/"):
                    if 'Contents' in page:
                        for obj in page['Contents']:
                            total_size += obj['Size']
                            file_count += 1
                            
                            # Compter les sauvegardes
                            if 'saves/' in obj['Key'] and obj['Key'].endswith('.json'):
                                save_count += 1
        
        except Exception as e:
            print(f"Erreur lors du calcul de l'utilisation du stockage: {e}")
            # En cas d'erreur, retourner des valeurs par défaut
            return {
                "total_size": 0,
                "total_size_mb": 0,
                "file_count": 0,
                "save_count": 0,
                "error": str(e)
            }
        
        # Convertir la taille en Mo avec 2 décimales
        total_size_mb = round(total_size / (1024 * 1024), 2)
        
        return {
            "total_size": total_size,
            "total_size_mb": total_size_mb,
            "file_count": file_count,
            "save_count": save_count
        }
