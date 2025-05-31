from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional, Dict, Any
from app.db.database import get_db
from app.models.schemas import (
    FriendRequestCreate, FriendRequest, FriendRequestUpdate,
    LeaderboardCreate, Leaderboard, LeaderboardEntryCreate, LeaderboardEntry,
    AchievementCreate, Achievement, UserAchievementCreate, UserAchievement
)
from app.models.user import User
from app.auth.jwt import get_current_user
from app.services.social import SocialService

# Initialiser le service social
social_service = SocialService()

router = APIRouter(prefix="/social", tags=["Social"])

# Routes pour la gestion des amis
@router.post("/friends/requests", response_model=FriendRequest, status_code=status.HTTP_201_CREATED)
async def send_friend_request(
    request_data: FriendRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Envoie une demande d'amitié à un autre utilisateur"""
    # Vérifier que l'utilisateur cible existe
    receiver = db.query(User).filter(User.id == request_data.receiver_id).first()
    if not receiver:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur cible non trouvé"
        )
    
    # Vérifier que ce n'est pas une demande à soi-même
    if current_user.id == request_data.receiver_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vous ne pouvez pas vous envoyer une demande d'amitié à vous-même"
        )
    
    # Utiliser le service pour envoyer la demande d'amitié
    try:
        new_request = social_service.send_friend_request(
            db=db,
            sender_id=current_user.id,
            receiver_id=request_data.receiver_id
        )
        return new_request
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors de l'envoi de la demande d'amitié: {str(e)}"
        )

@router.get("/friends/requests", response_model=List[Dict[str, Any]])
async def get_friend_requests(
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère toutes les demandes d'amitié de l'utilisateur actuel"""
    try:
        requests = social_service.get_friend_requests(
            db=db,
            user_id=current_user.id,
            status=status
        )
        return requests
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des demandes d'amitié: {str(e)}"
        )

@router.put("/friends/requests/{request_id}", response_model=FriendRequest)
async def respond_to_friend_request(
    request_id: str,
    response_data: FriendRequestUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Répond à une demande d'amitié (accepter ou rejeter)"""
    try:
        # Utiliser le service pour répondre à la demande d'amitié
        updated_request = social_service.respond_to_friend_request(
            db=db,
            request_id=request_id,
            status=response_data.status,
            user_id=current_user.id
        )
        
        if not updated_request:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Demande d'amitié non trouvée ou vous n'êtes pas le destinataire"
            )
        
        return updated_request
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la réponse à la demande d'amitié: {str(e)}"
        )

@router.get("/friends", response_model=List[Dict[str, Any]])
async def get_friends(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère la liste des amis de l'utilisateur actuel"""
    try:
        friends = social_service.get_friends(
            db=db,
            user_id=current_user.id
        )
        return friends
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des amis: {str(e)}"
        )

# Routes pour les classements
@router.post("/leaderboards", response_model=Leaderboard, status_code=status.HTTP_201_CREATED)
async def create_leaderboard(
    leaderboard_data: LeaderboardCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crée un nouveau classement (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent créer des classements"
        )
    
    try:
        # Utiliser le service pour créer le classement
        new_leaderboard = social_service.create_leaderboard(
            db=db,
            name=leaderboard_data.name,
            description=leaderboard_data.description,
            is_active=leaderboard_data.is_active
        )
        return new_leaderboard
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors de la création du classement: {str(e)}"
        )

@router.get("/leaderboards", response_model=List[Leaderboard])
async def get_leaderboards(
    db: Session = Depends(get_db)
):
    """Récupère tous les classements actifs"""
    try:
        # Utiliser le service pour récupérer les classements actifs
        leaderboards = db.query(Leaderboard).filter(
            Leaderboard.is_active == True
        ).all()
        return leaderboards
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des classements: {str(e)}"
        )

@router.post("/leaderboards/{leaderboard_id}/entries", response_model=LeaderboardEntry)
async def submit_leaderboard_score(
    leaderboard_id: str,
    entry_data: LeaderboardEntryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Soumet un score pour un classement"""
    try:
        # Utiliser le service pour soumettre le score
        entry = social_service.submit_score(
            db=db,
            leaderboard_id=leaderboard_id,
            user_id=current_user.id,
            score=entry_data.score
        )
        
        if not entry:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Classement non trouvé ou inactif"
            )
        
        # Mettre à jour les rangs du classement
        social_service.update_leaderboard_ranks(db, leaderboard_id)
        
        return entry
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la soumission du score: {str(e)}"
        )

@router.get("/leaderboards/{leaderboard_id}/entries", response_model=List[Dict[str, Any]])
async def get_leaderboard_entries(
    leaderboard_id: str,
    limit: int = 100,
    user_id: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère les entrées d'un classement"""
    try:
        # Si user_id n'est pas spécifié mais que l'utilisateur est connecté,
        # on peut utiliser son ID pour récupérer sa position
        if not user_id and current_user:
            user_id = current_user.id
            
        # Utiliser le service pour récupérer les entrées du classement
        entries = social_service.get_leaderboard_entries(
            db=db,
            leaderboard_id=leaderboard_id,
            limit=limit,
            user_id=user_id
        )
        
        if entries is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Classement non trouvé ou inactif"
            )
            
        return entries
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des entrées du classement: {str(e)}"
        )

# Routes pour les succès
@router.post("/achievements", response_model=Achievement, status_code=status.HTTP_201_CREATED)
async def create_achievement(
    achievement_data: AchievementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crée un nouveau succès (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent créer des succès"
        )
    
    try:
        # Utiliser le service pour créer le succès
        new_achievement = social_service.create_achievement(
            db=db,
            name=achievement_data.name,
            description=achievement_data.description,
            icon_url=achievement_data.icon_url,
            points=achievement_data.points,
            is_active=achievement_data.is_active
        )
        return new_achievement
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors de la création du succès: {str(e)}"
        )

@router.get("/achievements", response_model=List[Dict[str, Any]])
async def get_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère tous les succès avec indication de ceux débloqués par l'utilisateur"""
    try:
        # Utiliser le service pour récupérer tous les succès
        achievements = social_service.get_all_achievements(
            db=db,
            user_id=current_user.id
        )
        return achievements
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des succès: {str(e)}"
        )

@router.post("/achievements/unlock", response_model=UserAchievement)
async def unlock_achievement(
    achievement_data: UserAchievementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Débloque un succès pour l'utilisateur actuel"""
    try:
        # Utiliser le service pour débloquer le succès
        user_achievement = social_service.unlock_achievement(
            db=db,
            achievement_id=achievement_data.achievement_id,
            user_id=current_user.id
        )
        
        if not user_achievement:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Succès non trouvé, inactif ou déjà débloqué"
            )
            
        return user_achievement
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors du déblocage du succès: {str(e)}"
        )

@router.get("/achievements/user", response_model=List[Dict[str, Any]])
async def get_user_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère tous les succès débloqués par l'utilisateur actuel"""
    try:
        # Utiliser le service pour récupérer les succès débloqués
        achievements = social_service.get_user_achievements(
            db=db,
            user_id=current_user.id
        )
        return achievements
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération des succès débloqués: {str(e)}"
        )
