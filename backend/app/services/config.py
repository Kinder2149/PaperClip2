import json
import os
from typing import Dict, Any, Optional, List
from sqlalchemy.orm import Session
from app.models.remote_config import RemoteConfig, ConfigVersion
from datetime import datetime
from dotenv import load_dotenv

# Chargement des variables d'environnement
load_dotenv()

class ConfigService:
    """Service pour gérer la configuration à distance"""
    
    @staticmethod
    def get_active_config(
        db: Session,
        app_version: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Récupère la configuration active
        
        Args:
            db: Session de base de données
            app_version: Version de l'application (optionnel)
            
        Returns:
            La configuration active
        """
        # Récupérer tous les paramètres actifs
        configs = db.query(RemoteConfig).filter(
            RemoteConfig.is_active == True
        ).all()
        
        result = {}
        for config in configs:
            # Vérifier les conditions d'application
            if config.condition and app_version:
                # Implémenter ici la logique de vérification des conditions
                # Par exemple: version minimale, plateforme, etc.
                # Pour l'instant, on ignore les conditions
                pass
            
            result[config.key] = config.value
        
        return result
    
    @staticmethod
    def get_config_by_version(
        db: Session,
        version: str
    ) -> Dict[str, Any]:
        """
        Récupère une configuration par sa version
        
        Args:
            db: Session de base de données
            version: Numéro de version
            
        Returns:
            La configuration pour cette version
        """
        # Récupérer la version spécifiée
        config_version = db.query(ConfigVersion).filter(
            ConfigVersion.version_number == version,
            ConfigVersion.is_active == True
        ).first()
        
        if not config_version:
            return {}
        
        return config_version.config_snapshot
    
    @staticmethod
    def create_config_parameter(
        db: Session,
        key: str,
        value: Any,
        description: Optional[str] = None,
        is_active: bool = True,
        version: str = "1.0.0",
        condition: Optional[str] = None
    ) -> RemoteConfig:
        """
        Crée un nouveau paramètre de configuration
        
        Args:
            db: Session de base de données
            key: Clé du paramètre
            value: Valeur du paramètre
            description: Description du paramètre (optionnel)
            is_active: Si le paramètre est actif (défaut: True)
            version: Version du paramètre (défaut: "1.0.0")
            condition: Condition d'application (optionnel)
            
        Returns:
            Le paramètre créé
        """
        # Vérifier si le paramètre existe déjà
        existing_config = db.query(RemoteConfig).filter(
            RemoteConfig.key == key
        ).first()
        
        if existing_config:
            # Mettre à jour le paramètre existant
            existing_config.value = value
            existing_config.description = description or existing_config.description
            existing_config.is_active = is_active
            existing_config.version = version
            existing_config.condition = condition
            
            db.commit()
            db.refresh(existing_config)
            
            return existing_config
        
        # Créer un nouveau paramètre
        new_config = RemoteConfig(
            key=key,
            value=value,
            description=description,
            is_active=is_active,
            version=version,
            condition=condition
        )
        
        db.add(new_config)
        db.commit()
        db.refresh(new_config)
        
        return new_config
    
    @staticmethod
    def update_config_parameter(
        db: Session,
        key: str,
        value: Any = None,
        description: Optional[str] = None,
        is_active: Optional[bool] = None,
        version: Optional[str] = None,
        condition: Optional[str] = None
    ) -> Optional[RemoteConfig]:
        """
        Met à jour un paramètre de configuration existant
        
        Args:
            db: Session de base de données
            key: Clé du paramètre
            value: Nouvelle valeur (optionnel)
            description: Nouvelle description (optionnel)
            is_active: Nouvel état actif (optionnel)
            version: Nouvelle version (optionnel)
            condition: Nouvelle condition (optionnel)
            
        Returns:
            Le paramètre mis à jour ou None si non trouvé
        """
        # Récupérer le paramètre existant
        config = db.query(RemoteConfig).filter(
            RemoteConfig.key == key
        ).first()
        
        if not config:
            return None
        
        # Mettre à jour les champs fournis
        if value is not None:
            config.value = value
        if description is not None:
            config.description = description
        if is_active is not None:
            config.is_active = is_active
        if version is not None:
            config.version = version
        if condition is not None:
            config.condition = condition
        
        db.commit()
        db.refresh(config)
        
        return config
    
    @staticmethod
    def delete_config_parameter(
        db: Session,
        key: str
    ) -> bool:
        """
        Supprime un paramètre de configuration
        
        Args:
            db: Session de base de données
            key: Clé du paramètre
            
        Returns:
            True si supprimé, False sinon
        """
        # Récupérer le paramètre existant
        config = db.query(RemoteConfig).filter(
            RemoteConfig.key == key
        ).first()
        
        if not config:
            return False
        
        db.delete(config)
        db.commit()
        
        return True
    
    @staticmethod
    def publish_config_version(
        db: Session,
        version_number: str,
        notes: Optional[str] = None,
        is_active: bool = True
    ) -> ConfigVersion:
        """
        Publie une nouvelle version de la configuration
        
        Args:
            db: Session de base de données
            version_number: Numéro de version
            notes: Notes de version (optionnel)
            is_active: Si la version est active (défaut: True)
            
        Returns:
            La version publiée
        """
        # Récupérer la configuration active
        active_configs = db.query(RemoteConfig).filter(
            RemoteConfig.is_active == True
        ).all()
        
        # Construire le snapshot de configuration
        config_snapshot = {}
        for config in active_configs:
            config_snapshot[config.key] = config.value
        
        # Créer la nouvelle version
        new_version = ConfigVersion(
            version_number=version_number,
            config_snapshot=config_snapshot,
            notes=notes,
            is_active=is_active
        )
        
        db.add(new_version)
        db.commit()
        db.refresh(new_version)
        
        return new_version
    
    @staticmethod
    def get_config_versions(
        db: Session,
        active_only: bool = False
    ) -> List[ConfigVersion]:
        """
        Récupère toutes les versions de configuration
        
        Args:
            db: Session de base de données
            active_only: Si on ne récupère que les versions actives (défaut: False)
            
        Returns:
            Liste des versions de configuration
        """
        query = db.query(ConfigVersion)
        
        if active_only:
            query = query.filter(ConfigVersion.is_active == True)
        
        return query.order_by(ConfigVersion.published_at.desc()).all()
    
    @staticmethod
    def export_config_to_file(
        db: Session,
        file_path: str,
        version: Optional[str] = None
    ) -> bool:
        """
        Exporte la configuration vers un fichier JSON
        
        Args:
            db: Session de base de données
            file_path: Chemin du fichier de sortie
            version: Version à exporter (optionnel, utilise la configuration active par défaut)
            
        Returns:
            True si l'export a réussi, False sinon
        """
        try:
            if version:
                # Exporter une version spécifique
                config = ConfigService.get_config_by_version(db, version)
            else:
                # Exporter la configuration active
                config = ConfigService.get_active_config(db)
            
            # Créer le répertoire parent si nécessaire
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            
            # Écrire dans le fichier
            with open(file_path, "w") as f:
                json.dump(config, f, indent=2)
            
            return True
        
        except Exception as e:
            print(f"Erreur lors de l'export de la configuration: {str(e)}")
            return False
    
    @staticmethod
    def import_config_from_file(
        db: Session,
        file_path: str,
        version: str = "imported",
        notes: Optional[str] = None
    ) -> Optional[ConfigVersion]:
        """
        Importe la configuration depuis un fichier JSON
        
        Args:
            db: Session de base de données
            file_path: Chemin du fichier d'entrée
            version: Numéro de version (défaut: "imported")
            notes: Notes de version (optionnel)
            
        Returns:
            La version importée ou None si échec
        """
        try:
            # Lire le fichier
            with open(file_path, "r") as f:
                config_data = json.load(f)
            
            # Créer la nouvelle version
            new_version = ConfigVersion(
                version_number=version,
                config_snapshot=config_data,
                notes=notes or f"Importé depuis {file_path}",
                is_active=True
            )
            
            db.add(new_version)
            db.commit()
            db.refresh(new_version)
            
            # Créer ou mettre à jour les paramètres individuels
            for key, value in config_data.items():
                ConfigService.create_config_parameter(
                    db=db,
                    key=key,
                    value=value,
                    description=f"Importé depuis {file_path}",
                    is_active=True,
                    version=version
                )
            
            return new_version
        
        except Exception as e:
            print(f"Erreur lors de l'import de la configuration: {str(e)}")
            return None
