from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app.db.database import get_db
from app.models.schemas import UserProfileSaveCreate, UserProfileSaveResponse
from app.models.user_profile_save import UserProfileSave
from app.models.game_save import GameSave
from app.models.user import User
from app.auth.jwt import get_current_user
import uuid

router = APIRouter(prefix="/user/profile", tags=["User Profile"])

@router.post("/saves", response_model=UserProfileSaveResponse)
async def add_save_to_profile(
    save_data: UserProfileSaveCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Ajoute une sauvegarde au profil de l'utilisateur"""
    
    # Vérifier que la sauvegarde existe
    save = db.query(GameSave).filter(GameSave.id == save_data.save_id).first()
    if not save:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Sauvegarde avec ID {save_data.save_id} non trouvée"
        )
    
    # Vérifier que la sauvegarde appartient à l'utilisateur
    if save.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cette sauvegarde ne vous appartient pas"
        )
        
    # Vérifier si cette sauvegarde est déjà dans le profil de l'utilisateur
    existing_profile_save = db.query(UserProfileSave).filter(
        UserProfileSave.user_id == current_user.id,
        UserProfileSave.save_id == save_data.save_id
    ).first()
    
    if existing_profile_save:
        # Mise à jour des données existantes
        existing_profile_save.game_mode = save_data.game_mode
        existing_profile_save.metadata = save_data.metadata
        db.commit()
        db.refresh(existing_profile_save)
        return existing_profile_save
    
    # Créer une nouvelle entrée
    user_profile_save = UserProfileSave(
        id=str(uuid.uuid4()),
        user_id=current_user.id,
        save_id=save_data.save_id,
        game_mode=save_data.game_mode,
        metadata=save_data.metadata
    )
    
    db.add(user_profile_save)
    db.commit()
    db.refresh(user_profile_save)
    
    return user_profile_save

@router.get("/saves", response_model=List[UserProfileSaveResponse])
async def get_user_profile_saves(
    game_mode: Optional[str] = Query(None, description="Filtrer par mode de jeu"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère les sauvegardes associées au profil de l'utilisateur"""
    
    query = db.query(UserProfileSave).filter(UserProfileSave.user_id == current_user.id)
    
    if game_mode:
        query = query.filter(UserProfileSave.game_mode == game_mode)
        
    profile_saves = query.all()
    
    return profile_saves

@router.get("/saves/{save_id}", response_model=UserProfileSaveResponse)
async def get_user_profile_save(
    save_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère une sauvegarde spécifique associée au profil de l'utilisateur"""
    
    profile_save = db.query(UserProfileSave).filter(
        UserProfileSave.user_id == current_user.id,
        UserProfileSave.save_id == save_id
    ).first()
    
    if not profile_save:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Sauvegarde avec ID {save_id} non trouvée dans votre profil"
        )
        
    return profile_save

@router.delete("/saves/{save_id}", response_model=dict)
async def remove_save_from_profile(
    save_id: str,
    delete_file: bool = Query(False, description="Supprimer également le fichier de sauvegarde"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Supprime une sauvegarde du profil de l'utilisateur"""
    
    profile_save = db.query(UserProfileSave).filter(
        UserProfileSave.user_id == current_user.id,
        UserProfileSave.save_id == save_id
    ).first()
    
    if not profile_save:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Sauvegarde avec ID {save_id} non trouvée dans votre profil"
        )
    
    # Supprimer du profil
    db.delete(profile_save)
    
    # Si demandé, supprimer également le fichier de sauvegarde
    if delete_file:
        save = db.query(GameSave).filter(GameSave.id == save_id).first()
        if save and save.user_id == current_user.id:
            db.delete(save)
    
    db.commit()
    
    return {
        "success": True,
        "message": f"Sauvegarde {save_id} retirée du profil" + 
                  (" et supprimée" if delete_file else "")
    }
