from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.models.user import User
from app.db.database import get_db
import os
from dotenv import load_dotenv
import uuid

# Chargement des variables d'environnement
load_dotenv()

# Configuration des secrets
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-for-development-only")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 jours

# Configuration de la sécurité
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/token")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Vérifie si un mot de passe correspond à son hash
    
    Args:
        plain_password: Mot de passe en clair
        hashed_password: Hash du mot de passe
        
    Returns:
        True si le mot de passe correspond, False sinon
    """
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    """
    Génère un hash pour un mot de passe
    
    Args:
        password: Mot de passe en clair
        
    Returns:
        Hash du mot de passe
    """
    return pwd_context.hash(password)

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """
    Crée un token JWT
    
    Args:
        data: Données à encoder dans le token
        expires_delta: Durée de validité du token (optionnel)
        
    Returns:
        Token JWT encodé
    """
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return encoded_jwt

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """
    Récupère un utilisateur par son email
    
    Args:
        db: Session de base de données
        email: Email de l'utilisateur
        
    Returns:
        L'utilisateur ou None si non trouvé
    """
    return db.query(User).filter(User.email == email).first()

def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    """
    Récupère un utilisateur par son ID
    
    Args:
        db: Session de base de données
        user_id: ID de l'utilisateur
        
    Returns:
        L'utilisateur ou None si non trouvé
    """
    return db.query(User).filter(User.id == user_id).first()

def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    """
    Authentifie un utilisateur
    
    Args:
        db: Session de base de données
        email: Email de l'utilisateur
        password: Mot de passe de l'utilisateur
        
    Returns:
        L'utilisateur authentifié ou None si échec
    """
    user = get_user_by_email(db, email)
    
    if not user:
        return None
    
    if not verify_password(password, user.password_hash):
        return None
    
    return user

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    """
    Récupère l'utilisateur courant à partir du token JWT
    
    Args:
        token: Token JWT
        db: Session de base de données
        
    Returns:
        L'utilisateur courant
        
    Raises:
        HTTPException: Si le token est invalide ou l'utilisateur n'existe pas
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants invalides",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise credentials_exception
        
    except JWTError:
        raise credentials_exception
    
    user = get_user_by_id(db, user_id)
    
    if user is None:
        raise credentials_exception
    
    return user

def create_user(
    db: Session,
    email: str,
    password: str,
    username: Optional[str] = None,
    provider: str = "email",
    provider_id: Optional[str] = None
) -> User:
    """
    Crée un nouvel utilisateur
    
    Args:
        db: Session de base de données
        email: Email de l'utilisateur
        password: Mot de passe de l'utilisateur
        username: Nom d'utilisateur (optionnel)
        provider: Fournisseur d'authentification (défaut: "email")
        provider_id: ID du fournisseur (optionnel)
        
    Returns:
        L'utilisateur créé
        
    Raises:
        HTTPException: Si l'email est déjà utilisé
    """
    # Vérifier si l'email est déjà utilisé
    db_user = get_user_by_email(db, email)
    
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email déjà enregistré"
        )
    
    # Générer un hash pour le mot de passe
    password_hash = get_password_hash(password)
    
    # Générer un nom d'utilisateur si non fourni
    if not username:
        username = f"user_{uuid.uuid4().hex[:8]}"
    
    # Créer l'utilisateur
    user = User(
        email=email,
        username=username,
        password_hash=password_hash,
        provider=provider,
        provider_id=provider_id,
        is_active=True
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user

def authenticate_with_provider(
    db: Session,
    provider: str,
    provider_id: str,
    email: str,
    username: Optional[str] = None,
    profile_image_url: Optional[str] = None
) -> User:
    """
    Authentifie un utilisateur avec un fournisseur tiers (Google, Apple, etc.)
    
    Args:
        db: Session de base de données
        provider: Fournisseur d'authentification
        provider_id: ID du fournisseur
        email: Email de l'utilisateur
        username: Nom d'utilisateur (optionnel)
        profile_image_url: URL de l'image de profil (optionnel)
        
    Returns:
        L'utilisateur authentifié ou créé
    """
    # Vérifier si l'utilisateur existe déjà avec ce provider_id
    user = db.query(User).filter(
        User.provider == provider,
        User.provider_id == provider_id
    ).first()
    
    if user:
        # Mettre à jour les informations si nécessaire
        if username and not user.username:
            user.username = username
        if profile_image_url and not user.profile_image_url:
            user.profile_image_url = profile_image_url
        
        db.commit()
        db.refresh(user)
        
        return user
    
    # Vérifier si l'email est déjà utilisé
    user = get_user_by_email(db, email)
    
    if user:
        # Lier le compte existant au fournisseur
        user.provider = provider
        user.provider_id = provider_id
        
        if profile_image_url and not user.profile_image_url:
            user.profile_image_url = profile_image_url
        
        db.commit()
        db.refresh(user)
        
        return user
    
    # Créer un nouvel utilisateur
    user = User(
        email=email,
        username=username or f"{provider}_user_{uuid.uuid4().hex[:8]}",
        provider=provider,
        provider_id=provider_id,
        profile_image_url=profile_image_url,
        is_active=True
    )
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return user

def change_password(
    db: Session,
    user_id: str,
    current_password: str,
    new_password: str
) -> bool:
    """
    Change le mot de passe d'un utilisateur
    
    Args:
        db: Session de base de données
        user_id: ID de l'utilisateur
        current_password: Mot de passe actuel
        new_password: Nouveau mot de passe
        
    Returns:
        True si le mot de passe a été changé, False sinon
    """
    # Récupérer l'utilisateur
    user = get_user_by_id(db, user_id)
    
    if not user:
        return False
    
    # Vérifier le mot de passe actuel
    if not verify_password(current_password, user.password_hash):
        return False
    
    # Mettre à jour le mot de passe
    user.password_hash = get_password_hash(new_password)
    db.commit()
    
    return True

def reset_password_request(
    db: Session,
    email: str
) -> Optional[str]:
    """
    Demande de réinitialisation de mot de passe
    
    Args:
        db: Session de base de données
        email: Email de l'utilisateur
        
    Returns:
        Token de réinitialisation ou None si l'utilisateur n'existe pas
    """
    # Récupérer l'utilisateur
    user = get_user_by_email(db, email)
    
    if not user:
        return None
    
    # Générer un token de réinitialisation
    reset_token = create_access_token(
        data={"sub": user.id, "type": "reset_password"},
        expires_delta=timedelta(hours=1)
    )
    
    # Stocker le token dans la base de données
    user.reset_token = reset_token
    user.reset_token_expires = datetime.utcnow() + timedelta(hours=1)
    db.commit()
    
    return reset_token

def reset_password_confirm(
    db: Session,
    token: str,
    new_password: str
) -> bool:
    """
    Confirme la réinitialisation de mot de passe
    
    Args:
        db: Session de base de données
        token: Token de réinitialisation
        new_password: Nouveau mot de passe
        
    Returns:
        True si le mot de passe a été réinitialisé, False sinon
    """
    try:
        # Décoder le token
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        
        if user_id is None or token_type != "reset_password":
            return False
        
        # Récupérer l'utilisateur
        user = get_user_by_id(db, user_id)
        
        if not user or user.reset_token != token:
            return False
        
        # Vérifier l'expiration du token
        if user.reset_token_expires and user.reset_token_expires < datetime.utcnow():
            return False
        
        # Mettre à jour le mot de passe
        user.password_hash = get_password_hash(new_password)
        user.reset_token = None
        user.reset_token_expires = None
        db.commit()
        
        return True
        
    except JWTError:
        return False
