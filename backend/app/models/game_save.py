from sqlalchemy import Column, String, DateTime, Integer, Text, ForeignKey, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
import uuid

class GameSave(Base):
    """Modèle de données pour les sauvegardes de jeu"""
    __tablename__ = "game_saves"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name = Column(String, index=True)  # Nom de la sauvegarde
    data = Column(Text)  # Données de sauvegarde JSON encodées
    version = Column(String)  # Version du jeu
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    is_auto_save = Column(Boolean, default=False)
    
    # Statistiques de jeu
    level = Column(Integer, default=1)
    metal = Column(Integer, default=0)
    clips_produced = Column(Integer, default=0)
    
    # Relation avec l'utilisateur
    user = relationship("User", backref="game_saves")
    
    # Métadonnées supplémentaires
    device_info = Column(String, nullable=True)  # Informations sur l'appareil
    play_time = Column(Integer, default=0)  # Temps de jeu en secondes
