from sqlalchemy import Column, String, Boolean, DateTime, Integer
from sqlalchemy.sql import func
from app.db.database import Base
import uuid

class User(Base):
    """Modèle de données pour les utilisateurs de l'application"""
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True)
    username = Column(String, index=True)
    hashed_password = Column(String)
    profile_image_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Champs spécifiques pour remplacer les fonctionnalités Firebase
    last_login = Column(DateTime(timezone=True), nullable=True)
    email_verified = Column(Boolean, default=False)
    provider = Column(String, default="email")  # email, google, etc.
    provider_id = Column(String, nullable=True)  # ID externe du fournisseur d'authentification
    
    # Champs pour les statistiques utilisateur
    xp_total = Column(Integer, default=0)
    level = Column(Integer, default=1)
    games_played = Column(Integer, default=0)
    highest_score = Column(Integer, default=0)
