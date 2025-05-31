import os
import uuid
import shutil
from fastapi import UploadFile
from pathlib import Path
import boto3
from botocore.exceptions import ClientError
from dotenv import load_dotenv
import mimetypes

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

async def upload_file(file: UploadFile, path: str, user_id: str) -> str:
    """
    Télécharge un fichier vers le stockage (local ou S3)
    
    Args:
        file: Le fichier à télécharger
        path: Le chemin de destination dans le stockage
        user_id: L'ID de l'utilisateur
        
    Returns:
        L'URL du fichier téléchargé
    """
    # Générer un nom de fichier unique
    filename = f"{uuid.uuid4()}_{file.filename}"
    
    # Construire le chemin complet
    full_path = f"{user_id}/{path}/{filename}"
    
    if STORAGE_TYPE == "local":
        # Stockage local
        local_path = os.path.join(LOCAL_STORAGE_PATH, full_path)
        
        # Créer le répertoire parent s'il n'existe pas
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        
        # Enregistrer le fichier
        with open(local_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Retourner l'URL relative
        return f"/api/storage/download/{full_path}"
    
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
        
        # Retourner l'URL S3
        return f"https://{S3_BUCKET}.s3.{S3_REGION}.amazonaws.com/{full_path}"
    
    else:
        raise ValueError("Configuration de stockage invalide")

async def upload_profile_image(file: UploadFile, user_id: str) -> str:
    """
    Télécharge une image de profil
    
    Args:
        file: L'image à télécharger
        user_id: L'ID de l'utilisateur
        
    Returns:
        L'URL de l'image téléchargée
    """
    return await upload_file(file, "profiles", user_id)

async def download_file(path: str, user_id: str):
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

async def delete_file(path: str, user_id: str):
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
