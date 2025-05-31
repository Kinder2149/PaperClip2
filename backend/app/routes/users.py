from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models.schemas import UserProfile, UserProfileUpdate
from app.models.user import User
from app.auth.jwt import get_current_user
from app.services.storage import StorageService

router = APIRouter(prefix="/users", tags=["Users"])

# Initialiser le service de stockage
storage_service = StorageService()

@router.get("/", response_model=List[UserProfile])
async def get_users(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère la liste des utilisateurs (limité aux administrateurs en production)"""
    users = db.query(User).offset(skip).limit(limit).all()
    return users

@router.get("/{user_id}", response_model=UserProfile)
async def get_user(
    user_id: str, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère les informations d'un utilisateur spécifique"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    return user

@router.put("/me", response_model=UserProfile)
async def update_user_profile(
    profile_data: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Met à jour le profil de l'utilisateur actuel"""
    # Mettre à jour les champs fournis
    if profile_data.username:
        current_user.username = profile_data.username
    if profile_data.profile_image_url:
        current_user.profile_image_url = profile_data.profile_image_url
    
    db.commit()
    db.refresh(current_user)
    
    return current_user

@router.post("/me/profile-image", response_model=UserProfile)
async def upload_user_profile_image(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Télécharge et met à jour l'image de profil de l'utilisateur"""
    # Vérifier le type de fichier
    if not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le fichier doit être une image"
        )
    
    # Télécharger l'image vers le service de stockage
    file_id, image_url = await storage_service.upload_profile_image(file, current_user.id)
    
    # Mettre à jour l'URL de l'image de profil
    current_user.profile_image_url = image_url
    db.commit()
    db.refresh(current_user)
    
    return current_user

@router.get("/me/stats")
async def get_user_stats(current_user: User = Depends(get_current_user)):
    """Récupère les statistiques de l'utilisateur actuel"""
    return {
        "xp_total": current_user.xp_total,
        "level": current_user.level,
        "games_played": current_user.games_played,
        "highest_score": current_user.highest_score
    }

@router.put("/me/stats")
async def update_user_stats(
    xp: int = None,
    games_played: int = None,
    highest_score: int = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Met à jour les statistiques de l'utilisateur actuel"""
    # Mettre à jour les statistiques fournies
    if xp is not None:
        current_user.xp_total += xp
        # Calculer le nouveau niveau (à adapter selon votre formule)
        current_user.level = max(1, int(current_user.xp_total / 1000) + 1)
    
    if games_played is not None:
        current_user.games_played += games_played
    
    if highest_score is not None and highest_score > current_user.highest_score:
        current_user.highest_score = highest_score
    
    db.commit()
    db.refresh(current_user)
    
    return {
        "xp_total": current_user.xp_total,
        "level": current_user.level,
        "games_played": current_user.games_played,
        "highest_score": current_user.highest_score
    }
