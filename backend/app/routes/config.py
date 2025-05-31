from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Dict, Any, Optional
from app.db.database import get_db
from app.models.schemas import RemoteConfigCreate, RemoteConfig, ConfigVersionCreate, ConfigVersion
from app.models.remote_config import RemoteConfig as RemoteConfigModel, ConfigVersion as ConfigVersionModel
from app.models.user import User
from app.auth.jwt import get_current_user
from app.services.config import ConfigService

router = APIRouter(prefix="/config", tags=["Remote Config"])

# Initialiser le service de configuration
config_service = ConfigService()

@router.get("/", response_model=Dict[str, Any])
async def get_remote_config(
    version: Optional[str] = None,
    app_version: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Récupère la configuration à distance active"""
    # Si une version spécifique est demandée, récupérer cette version
    if version:
        config = config_service.get_config_by_version(db, version)
        
        if not config:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Version de configuration non trouvée"
            )
        
        return config
    
    # Sinon, récupérer la configuration active
    return config_service.get_active_config(db, app_version)

@router.post("/parameters", response_model=RemoteConfig, status_code=status.HTTP_201_CREATED)
async def create_config_parameter(
    config_data: RemoteConfigCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crée un nouveau paramètre de configuration à distance (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent créer des paramètres de configuration"
        )
    
    # Créer le nouveau paramètre avec le service
    new_config = config_service.create_config_parameter(
        db=db,
        key=config_data.key,
        value=config_data.value,
        description=config_data.description,
        is_active=config_data.is_active,
        version=config_data.version,
        condition=config_data.condition
    )
    
    return new_config

@router.put("/parameters/{key}", response_model=RemoteConfig)
async def update_config_parameter(
    key: str,
    config_data: RemoteConfigCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Met à jour un paramètre de configuration existant (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent mettre à jour des paramètres de configuration"
        )
    
    # Mettre à jour le paramètre avec le service
    updated_config = config_service.update_config_parameter(
        db=db,
        key=key,
        value=config_data.value,
        description=config_data.description,
        is_active=config_data.is_active,
        version=config_data.version,
        condition=config_data.condition
    )
    
    if not updated_config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paramètre de configuration non trouvé"
        )
    
    return updated_config

@router.delete("/parameters/{key}")
async def delete_config_parameter(
    key: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Supprime un paramètre de configuration (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent supprimer des paramètres de configuration"
        )
    
    # Supprimer le paramètre avec le service
    success = config_service.delete_config_parameter(db, key)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Paramètre de configuration non trouvé"
        )
    
    return {"message": "Paramètre de configuration supprimé avec succès"}

@router.post("/publish", response_model=ConfigVersion)
async def publish_config_version(
    version_data: ConfigVersionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Publie une nouvelle version de la configuration (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent publier des versions de configuration"
        )
    
    # Publier la nouvelle version avec le service
    new_version = config_service.publish_config_version(
        db=db,
        version_number=version_data.version_number,
        notes=version_data.notes,
        is_active=version_data.is_active
    )
    
    return new_version

@router.get("/versions", response_model=List[ConfigVersion])
async def get_config_versions(
    active_only: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Récupère toutes les versions de configuration (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent voir les versions de configuration"
        )
    
    # Récupérer les versions avec le service
    versions = config_service.get_config_versions(db, active_only)
    return versions

@router.post("/export")
async def export_config(
    file_path: str,
    version: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Exporte la configuration vers un fichier JSON (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent exporter la configuration"
        )
    
    # Exporter la configuration avec le service
    success = config_service.export_config_to_file(db, file_path, version)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'export de la configuration"
        )
    
    return {"message": "Configuration exportée avec succès", "file_path": file_path}

@router.post("/import", response_model=ConfigVersion)
async def import_config(
    file_path: str,
    version: str = "imported",
    notes: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Importe la configuration depuis un fichier JSON (admin uniquement)"""
    # Vérifier si l'utilisateur est admin
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les administrateurs peuvent importer la configuration"
        )
    
    # Importer la configuration avec le service
    new_version = config_service.import_config_from_file(db, file_path, version, notes)
    
    if not new_version:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erreur lors de l'import de la configuration"
        )
    
    return new_version
