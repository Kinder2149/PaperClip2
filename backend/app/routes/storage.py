from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form, BackgroundTasks
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.database import get_db
from app.models.schemas import GameSaveCreate, GameSave
from app.models.game_save import GameSave as GameSaveModel
from app.models.user import User
from app.auth.jwt import get_current_user
from app.services.storage import StorageService
from datetime import datetime
import os
import shutil
import uuid

router = APIRouter(prefix="/storage", tags=["Storage"])

# Initialiser le service de stockage
storage_service = StorageService()

@router.get("/status")
async def get_storage_status(
    current_user: User = Depends(get_current_user)
):
    """Retourne le statut du service de stockage et l'utilisation de l'utilisateur"""
    try:
        # Vérifier si le service de stockage est disponible
        storage_type = storage_service.get_storage_type()
        usage_info = storage_service.get_usage_info(current_user.id)
        
        return {
            "status": "available",
            "storage_type": storage_type,
            "user_storage": usage_info
        }
    except Exception as e:
        return {
            "status": "unavailable",
            "error": str(e)
        }

@router.post("/saves", response_model=GameSave, status_code=status.HTTP_201_CREATED)
async def create_game_save(
    save_data: GameSaveCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crée une nouvelle sauvegarde de jeu pour l'utilisateur actuel"""
    # Créer une nouvelle sauvegarde
    new_save = GameSaveModel(
        user_id=current_user.id,
        name=save_data.name,
        data=save_data.data,
        version=save_data.version,
        is_auto_save=save_data.is_auto_save,
        device_info=save_data.device_info,
        play_time=save_data.play_time,
        level=save_data.level,
        metal=save_data.metal,
        clips_produced=save_data.clips_produced
    )
    
    db.add(new_save)
    db.commit()
    db.refresh(new_save)
    
    # Sauvegarder les données dans le stockage
    try:
        storage_service.save_game_data(current_user.id, new_save.id, save_data.data)
    except Exception as e:
        # Si l'enregistrement dans le stockage échoue, on continue quand même
        # mais on pourrait logger l'erreur
        print(f"Erreur lors de la sauvegarde dans le stockage: {str(e)}")
    
    return new_save

@router.get("/saves", response_model=List[GameSave])
async def get_game_saves(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère toutes les sauvegardes de jeu de l'utilisateur actuel"""
    saves = db.query(GameSaveModel).filter(
        GameSaveModel.user_id == current_user.id
    ).order_by(GameSaveModel.updated_at.desc()).all()
    
    # Pour chaque sauvegarde, on pourrait récupérer les données depuis le stockage
    # Mais pour des raisons de performance, on ne le fait que lorsqu'une sauvegarde spécifique est demandée
    
    return saves

@router.get("/saves/{save_id}", response_model=GameSave)
async def get_game_save(
    save_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère une sauvegarde de jeu spécifique de l'utilisateur actuel"""
    save = db.query(GameSaveModel).filter(
        GameSaveModel.id == save_id,
        GameSaveModel.user_id == current_user.id
    ).first()
    
    if not save:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sauvegarde non trouvée"
        )
    
    # Essayer de récupérer les données depuis le stockage
    try:
        data = storage_service.get_game_data(current_user.id, save_id)
        if data:
            save.data = data
    except Exception as e:
        # Si la récupération depuis le stockage échoue, on utilise les données de la base
        print(f"Erreur lors de la récupération depuis le stockage: {str(e)}")
    
    return save

@router.put("/saves/{save_id}", response_model=GameSave)
async def update_game_save(
    save_id: str,
    save_data: GameSaveCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Met à jour une sauvegarde de jeu spécifique de l'utilisateur actuel"""
    save = db.query(GameSaveModel).filter(
        GameSaveModel.id == save_id,
        GameSaveModel.user_id == current_user.id
    ).first()
    
    if not save:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sauvegarde non trouvée"
        )
    
    # Mettre à jour les champs
    save.name = save_data.name
    save.data = save_data.data
    save.version = save_data.version
    save.is_auto_save = save_data.is_auto_save
    save.device_info = save_data.device_info
    save.play_time = save_data.play_time
    save.level = save_data.level
    save.metal = save_data.metal
    save.clips_produced = save_data.clips_produced
    save.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(save)
    
    # Mettre à jour les données dans le stockage
    try:
        storage_service.save_game_data(current_user.id, save_id, save_data.data)
    except Exception as e:
        # Si la mise à jour dans le stockage échoue, on continue quand même
        print(f"Erreur lors de la mise à jour dans le stockage: {str(e)}")
    
    return save

@router.delete("/saves/{save_id}")
async def delete_game_save(
    save_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Supprime une sauvegarde de jeu spécifique de l'utilisateur actuel"""
    save = db.query(GameSaveModel).filter(
        GameSaveModel.id == save_id,
        GameSaveModel.user_id == current_user.id
    ).first()
    
    if not save:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Sauvegarde non trouvée"
        )
    
    db.delete(save)
    db.commit()
    
    # Supprimer les données du stockage
    try:
        storage_service.delete_game_data(current_user.id, save_id)
    except Exception as e:
        # Si la suppression dans le stockage échoue, on continue quand même
        print(f"Erreur lors de la suppression dans le stockage: {str(e)}")
    
    return {"message": "Sauvegarde supprimée avec succès"}

@router.post("/files", status_code=status.HTTP_201_CREATED)
async def upload_file_endpoint(
    file: UploadFile = File(...),
    path: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user)
):
    """Télécharge un fichier dans le stockage"""
    try:
        # Utiliser le service de stockage pour télécharger le fichier
        file_id, file_url = storage_service.upload_file(
            file=file,
            user_id=current_user.id,
            path=path
        )
        
        return {
            "file_id": file_id,
            "filename": file.filename,
            "file_url": file_url
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors du téléchargement du fichier: {str(e)}"
        )

@router.get("/files/{user_id}/{file_path:path}")
async def get_file(
    user_id: str,
    file_path: str,
    current_user: User = Depends(get_current_user)
):
    """Récupère un fichier du serveur"""
    # Vérifier si l'utilisateur a accès à ce fichier
    if current_user.id != user_id:
        # Vérifier si le fichier est public ou si l'utilisateur est admin
        # Pour l'instant, on n'autorise que l'accès aux fichiers de l'utilisateur lui-même
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à ce fichier"
        )
    
    try:
        # Utiliser le service de stockage pour récupérer le fichier
        file_path, content_type = storage_service.get_file_path(user_id, file_path)
        
        if not file_path:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Fichier non trouvé"
            )
        
        return FileResponse(file_path, media_type=content_type)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération du fichier: {str(e)}"
        )

@router.delete("/files/{user_id}/{file_path:path}")
async def delete_file_endpoint(
    user_id: str,
    file_path: str,
    current_user: User = Depends(get_current_user)
):
    """Supprime un fichier du stockage"""
    # Vérifier si l'utilisateur a accès à ce fichier
    if current_user.id != user_id:
        # Vérifier si l'utilisateur est admin
        # Pour l'instant, on n'autorise que la suppression des fichiers de l'utilisateur lui-même
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous n'avez pas accès à ce fichier"
        )
    
    try:
        # Utiliser le service de stockage pour supprimer le fichier
        success = storage_service.delete_file(user_id, file_path)
        
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Fichier non trouvé"
            )
        
        return {"message": "Fichier supprimé avec succès"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la suppression du fichier: {str(e)}"
        )
