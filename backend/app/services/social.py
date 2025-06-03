from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_, desc, func
from app.models.social import (
    FriendRequest, Leaderboard, LeaderboardEntry, 
    Achievement, UserAchievement, friendship
)
from app.models.user import User
import uuid

class SocialService:
    @staticmethod
    def delete_friendship(db: Session, user_id: str, friend_id: str) -> None:
        """
        Supprime la relation d'amitié entre deux utilisateurs.
        Args:
            db: Session de base de données
            user_id: ID de l'utilisateur courant
            friend_id: ID de l'ami à supprimer
        """
        db.execute(
            "DELETE FROM friendships WHERE (user_id = :uid AND friend_id = :fid) OR (user_id = :fid AND friend_id = :uid)",
            {"uid": user_id, "fid": friend_id}
        )
        db.commit()

    """Service pour gérer les fonctionnalités sociales"""
    
    @staticmethod
    def get_friends(
        db: Session,
        user_id: str
    ) -> List[Dict[str, Any]]:
        """
        Récupère la liste des amis d'un utilisateur
        
        Args:
            db: Session de base de données
            user_id: ID de l'utilisateur
            
        Returns:
            Liste des amis
        """
        # Requête SQL pour récupérer les amis via la table d'association
        query = """
        SELECT u.id, u.username, u.profile_image_url, u.level, u.xp_total
        FROM users u
        JOIN friendships f ON u.id = f.friend_id
        WHERE f.user_id = :user_id AND f.status = 'accepted'
        """
        
        result = db.execute(query, {"user_id": user_id})
        friends = [dict(row) for row in result]
        
        return friends
    
    @staticmethod
    def send_friend_request(
        db: Session,
        sender_id: str,
        receiver_id: str
    ) -> FriendRequest:
        """
        Envoie une demande d'amitié
        
        Args:
            db: Session de base de données
            sender_id: ID de l'expéditeur
            receiver_id: ID du destinataire
            
        Returns:
            La demande d'amitié créée
        """
        # Vérifier si une demande existe déjà
        existing_request = db.query(FriendRequest).filter(
            or_(
                and_(
                    FriendRequest.sender_id == sender_id,
                    FriendRequest.receiver_id == receiver_id
                ),
                and_(
                    FriendRequest.sender_id == receiver_id,
                    FriendRequest.receiver_id == sender_id
                )
            )
        ).first()
        
        if existing_request:
            return existing_request
        
        # Créer la demande d'amitié
        new_request = FriendRequest(
            sender_id=sender_id,
            receiver_id=receiver_id,
            status="pending"
        )
        
        db.add(new_request)
        db.commit()
        db.refresh(new_request)
        
        return new_request
    
    @staticmethod
    def respond_to_friend_request(
        db: Session,
        request_id: str,
        status: str,
        user_id: str
    ) -> Optional[FriendRequest]:
        """
        Répond à une demande d'amitié
        
        Args:
            db: Session de base de données
            request_id: ID de la demande
            status: Nouveau statut (accepted, rejected)
            user_id: ID de l'utilisateur qui répond
            
        Returns:
            La demande d'amitié mise à jour ou None si non trouvée
        """
        # Récupérer la demande d'amitié
        friend_request = db.query(FriendRequest).filter(
            FriendRequest.id == request_id,
            FriendRequest.receiver_id == user_id
        ).first()
        
        if not friend_request:
            return None
        
        # Mettre à jour le statut
        friend_request.status = status
        db.commit()
        db.refresh(friend_request)
        
        # Si la demande est acceptée, créer la relation d'amitié
        if status == "accepted":
            # Insérer dans la table d'association friendship
            db.execute(
                friendship.insert().values(
                    user_id=friend_request.sender_id,
                    friend_id=friend_request.receiver_id,
                    status="accepted"
                )
            )
            db.execute(
                friendship.insert().values(
                    user_id=friend_request.receiver_id,
                    friend_id=friend_request.sender_id,
                    status="accepted"
                )
            )
            db.commit()
        
        return friend_request
    
    @staticmethod
    def get_friend_requests(
        db: Session,
        user_id: str,
        status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Récupère les demandes d'amitié d'un utilisateur
        
        Args:
            db: Session de base de données
            user_id: ID de l'utilisateur
            status: Filtre par statut (optionnel)
            
        Returns:
            Liste des demandes d'amitié
        """
        # Requête de base
        query = db.query(FriendRequest).filter(
            or_(
                FriendRequest.sender_id == user_id,
                FriendRequest.receiver_id == user_id
            )
        )
        
        # Filtrer par statut si spécifié
        if status:
            query = query.filter(FriendRequest.status == status)
        
        # Exécuter la requête
        requests = query.all()
        
        # Récupérer les informations des utilisateurs
        result = []
        for request in requests:
            # Déterminer l'autre utilisateur
            other_user_id = request.receiver_id if request.sender_id == user_id else request.sender_id
            other_user = db.query(User).filter(User.id == other_user_id).first()
            
            # Déterminer le type de demande
            request_type = "sent" if request.sender_id == user_id else "received"
            
            result.append({
                "id": request.id,
                "status": request.status,
                "type": request_type,
                "created_at": request.created_at,
                "updated_at": request.updated_at,
                "user": {
                    "id": other_user.id,
                    "username": other_user.username,
                    "profile_image_url": other_user.profile_image_url,
                    "level": other_user.level
                }
            })
        
        return result
    
    @staticmethod
    def create_leaderboard(
        db: Session,
        name: str,
        description: Optional[str] = None,
        is_active: bool = True
    ) -> Leaderboard:
        """
        Crée un nouveau classement
        
        Args:
            db: Session de base de données
            name: Nom du classement
            description: Description du classement (optionnel)
            is_active: Si le classement est actif (défaut: True)
            
        Returns:
            Le classement créé
        """
        # Vérifier si le classement existe déjà
        existing_leaderboard = db.query(Leaderboard).filter(
            Leaderboard.name == name
        ).first()
        
        if existing_leaderboard:
            return existing_leaderboard
        
        # Créer le nouveau classement
        new_leaderboard = Leaderboard(
            name=name,
            description=description,
            is_active=is_active
        )
        
        db.add(new_leaderboard)
        db.commit()
        db.refresh(new_leaderboard)
        
        return new_leaderboard
    
    @staticmethod
    def submit_score(
        db: Session,
        leaderboard_id: str,
        user_id: str,
        score: int
    ) -> LeaderboardEntry:
        """
        Soumet un score pour un classement
        
        Args:
            db: Session de base de données
            leaderboard_id: ID du classement
            user_id: ID de l'utilisateur
            score: Score à soumettre
            
        Returns:
            L'entrée de classement créée ou mise à jour
        """
        # Vérifier si l'utilisateur a déjà un score pour ce classement
        existing_entry = db.query(LeaderboardEntry).filter(
            LeaderboardEntry.leaderboard_id == leaderboard_id,
            LeaderboardEntry.user_id == user_id
        ).first()
        
        if existing_entry:
            # Mettre à jour le score existant si le nouveau score est meilleur
            if score > existing_entry.score:
                existing_entry.score = score
                db.commit()
                db.refresh(existing_entry)
                
                # Recalculer les rangs
                SocialService.update_leaderboard_ranks(db, leaderboard_id)
                
                return existing_entry
            else:
                return existing_entry
        
        # Créer une nouvelle entrée de classement
        new_entry = LeaderboardEntry(
            leaderboard_id=leaderboard_id,
            user_id=user_id,
            score=score
        )
        
        db.add(new_entry)
        db.commit()
        db.refresh(new_entry)
        
        # Calculer le rang
        SocialService.update_leaderboard_ranks(db, leaderboard_id)
        
        return new_entry
    
    @staticmethod
    def update_leaderboard_ranks(
        db: Session,
        leaderboard_id: str
    ) -> None:
        """
        Met à jour les rangs d'un classement
        
        Args:
            db: Session de base de données
            leaderboard_id: ID du classement
        """
        # Récupérer toutes les entrées du classement, triées par score décroissant
        entries = db.query(LeaderboardEntry).filter(
            LeaderboardEntry.leaderboard_id == leaderboard_id
        ).order_by(desc(LeaderboardEntry.score)).all()
        
        # Mettre à jour les rangs
        for i, entry in enumerate(entries):
            entry.rank = i + 1
        
        db.commit()
    
    @staticmethod
    def get_leaderboard_entries(
        db: Session,
        leaderboard_id: str,
        limit: int = 100,
        user_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Récupère les entrées d'un classement
        
        Args:
            db: Session de base de données
            leaderboard_id: ID du classement
            limit: Nombre maximum d'entrées à récupérer
            user_id: ID de l'utilisateur pour inclure son rang (optionnel)
            
        Returns:
            Liste des entrées de classement
        """
        # Requête SQL pour récupérer les entrées avec les informations utilisateur
        query = """
        SELECT le.id, le.score, le.rank, le.timestamp, 
               u.id as user_id, u.username, u.profile_image_url
        FROM leaderboard_entries le
        JOIN users u ON le.user_id = u.id
        WHERE le.leaderboard_id = :leaderboard_id
        ORDER BY le.score DESC
        LIMIT :limit
        """
        
        result = db.execute(query, {"leaderboard_id": leaderboard_id, "limit": limit})
        entries = [dict(row) for row in result]
        
        # Si un utilisateur est spécifié, récupérer son rang
        user_entry = None
        if user_id:
            user_query = """
            SELECT le.id, le.score, le.rank, le.timestamp, 
                   u.id as user_id, u.username, u.profile_image_url
            FROM leaderboard_entries le
            JOIN users u ON le.user_id = u.id
            WHERE le.leaderboard_id = :leaderboard_id AND le.user_id = :user_id
            """
            
            user_result = db.execute(user_query, {"leaderboard_id": leaderboard_id, "user_id": user_id})
            user_entries = [dict(row) for row in user_result]
            
            if user_entries:
                user_entry = user_entries[0]
        
        return {
            "entries": entries,
            "user_entry": user_entry,
            "total_entries": db.query(LeaderboardEntry).filter(
                LeaderboardEntry.leaderboard_id == leaderboard_id
            ).count()
        }
    
    @staticmethod
    def create_achievement(
        db: Session,
        name: str,
        description: str,
        icon_url: Optional[str] = None,
        points: int = 0,
        is_active: bool = True
    ) -> Achievement:
        """
        Crée un nouveau succès
        
        Args:
            db: Session de base de données
            name: Nom du succès
            description: Description du succès
            icon_url: URL de l'icône (optionnel)
            points: Points accordés (défaut: 0)
            is_active: Si le succès est actif (défaut: True)
            
        Returns:
            Le succès créé
        """
        # Vérifier si le succès existe déjà
        existing_achievement = db.query(Achievement).filter(
            Achievement.name == name
        ).first()
        
        if existing_achievement:
            return existing_achievement
        
        # Créer le nouveau succès
        new_achievement = Achievement(
            name=name,
            description=description,
            icon_url=icon_url,
            points=points,
            is_active=is_active
        )
        
        db.add(new_achievement)
        db.commit()
        db.refresh(new_achievement)
        
        return new_achievement
    
    @staticmethod
    def unlock_achievement(
        db: Session,
        achievement_id: str,
        user_id: str
    ) -> Optional[UserAchievement]:
        """
        Débloque un succès pour un utilisateur
        
        Args:
            db: Session de base de données
            achievement_id: ID du succès
            user_id: ID de l'utilisateur
            
        Returns:
            Le succès débloqué ou None si déjà débloqué
        """
        # Vérifier si le succès existe
        achievement = db.query(Achievement).filter(
            Achievement.id == achievement_id,
            Achievement.is_active == True
        ).first()
        
        if not achievement:
            return None
        
        # Vérifier si l'utilisateur a déjà débloqué ce succès
        existing_unlock = db.query(UserAchievement).filter(
            UserAchievement.achievement_id == achievement_id,
            UserAchievement.user_id == user_id
        ).first()
        
        if existing_unlock:
            return existing_unlock
        
        # Créer un nouveau déblocage de succès
        new_unlock = UserAchievement(
            achievement_id=achievement_id,
            user_id=user_id
        )
        
        db.add(new_unlock)
        db.commit()
        db.refresh(new_unlock)
        
        # Mettre à jour les points XP de l'utilisateur
        user = db.query(User).filter(User.id == user_id).first()
        if user:
            user.xp_total += achievement.points
            db.commit()
        
        return new_unlock
    
    @staticmethod
    def get_user_achievements(
        db: Session,
        user_id: str
    ) -> List[Dict[str, Any]]:
        """
        Récupère les succès débloqués par un utilisateur
        
        Args:
            db: Session de base de données
            user_id: ID de l'utilisateur
            
        Returns:
            Liste des succès débloqués
        """
        # Requête SQL pour récupérer les succès débloqués avec leurs détails
        query = """
        SELECT a.id, a.name, a.description, a.icon_url, a.points, ua.unlocked_at
        FROM achievements a
        JOIN user_achievements ua ON a.id = ua.achievement_id
        WHERE ua.user_id = :user_id
        """
        
        result = db.execute(query, {"user_id": user_id})
        achievements = [dict(row) for row in result]
        
        return achievements
    
    @staticmethod
    def get_all_achievements(
        db: Session,
        user_id: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Récupère tous les succès, avec indication de ceux débloqués par l'utilisateur
        
        Args:
            db: Session de base de données
            user_id: ID de l'utilisateur (optionnel)
            
        Returns:
            Liste de tous les succès
        """
        # Récupérer tous les succès actifs
        achievements = db.query(Achievement).filter(
            Achievement.is_active == True
        ).all()
        
        result = []
        for achievement in achievements:
            achievement_dict = {
                "id": achievement.id,
                "name": achievement.name,
                "description": achievement.description,
                "icon_url": achievement.icon_url,
                "points": achievement.points,
                "unlocked": False,
                "unlocked_at": None
            }
            
            # Si un utilisateur est spécifié, vérifier s'il a débloqué ce succès
            if user_id:
                user_achievement = db.query(UserAchievement).filter(
                    UserAchievement.achievement_id == achievement.id,
                    UserAchievement.user_id == user_id
                ).first()
                
                if user_achievement:
                    achievement_dict["unlocked"] = True
                    achievement_dict["unlocked_at"] = user_achievement.unlocked_at
            
            result.append(achievement_dict)
        
        return result
