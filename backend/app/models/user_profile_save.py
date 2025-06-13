from sqlalchemy import Column, String, DateTime, Integer, Text, ForeignKey, Boolean, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.database import Base
import uuid

class UserProfileSave(Base):
    """Modèle de données pour les sauvegardes associées au profil utilisateur"""
    __tablename__ = "user_profile_saves"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    save_id = Column(String, ForeignKey("game_saves.id", ondelete="CASCADE"), index=True)
    game_mode = Column(String, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Métadonnées supplémentaires (stockées en JSON)
    save_metadata = Column(JSON, nullable=True)
    
    # Relations
    user = relationship("User", backref="profile_saves")
    save = relationship("GameSave")
