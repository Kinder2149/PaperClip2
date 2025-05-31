from sqlalchemy import Column, String, DateTime, JSON, Boolean
from sqlalchemy.sql import func
from app.db.database import Base
import uuid

class RemoteConfig(Base):
    """Modèle de données pour la configuration à distance (remplace Firebase Remote Config)"""
    __tablename__ = "remote_configs"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    key = Column(String, unique=True, index=True)
    value = Column(JSON)  # Valeur de la configuration en JSON
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    is_active = Column(Boolean, default=True)
    
    # Métadonnées pour la gestion des versions
    version = Column(String, default="1.0.0")
    condition = Column(String, nullable=True)  # Condition d'application (ex: version minimale)

class ConfigVersion(Base):
    """Modèle pour gérer les versions de configuration"""
    __tablename__ = "config_versions"
    
    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    version_number = Column(String, unique=True, index=True)
    config_snapshot = Column(JSON)  # Snapshot complet de la configuration
    published_at = Column(DateTime(timezone=True), server_default=func.now())
    is_active = Column(Boolean, default=True)
    notes = Column(String, nullable=True)
