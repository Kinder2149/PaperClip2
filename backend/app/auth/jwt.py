from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.schemas import TokenData
import os
from dotenv import load_dotenv

# Chargement des variables d'environnement
load_dotenv()

# Configuration des clés secrètes et des paramètres JWT
# En production, utilisez des variables d'environnement pour ces valeurs
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "YOUR_SECRET_KEY_HERE_CHANGE_IN_PRODUCTION")
# Clé secrète spécifique pour les refresh tokens
REFRESH_SECRET_KEY = os.getenv("JWT_REFRESH_SECRET_KEY", SECRET_KEY)
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 jours
REFRESH_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30  # 30 jours

# Configuration de l'authentification OAuth2
# Utilisation d'un slash initial pour assurer le bon fonctionnement avec les URL relatives
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/token")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Crée un token JWT avec les données fournies et une date d'expiration"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    
    return encoded_jwt, expire

def create_refresh_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Crée un refresh token JWT avec les données fournies et une date d'expiration plus longue"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=REFRESH_TOKEN_EXPIRE_MINUTES)
        
    to_encode.update({"exp": expire, "token_type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, REFRESH_SECRET_KEY, algorithm=ALGORITHM)
    
    return encoded_jwt, expire

def verify_token(token: str, credentials_exception):
    """Vérifie la validité d'un token JWT et retourne les données décodées"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        
        if user_id is None:
            raise credentials_exception
            
        token_data = TokenData(user_id=user_id)
        return token_data
        
    except JWTError:
        raise credentials_exception

def verify_refresh_token(token: str):
    """Vérifie la validité d'un refresh token JWT et retourne les données décodées"""
    try:
        payload = jwt.decode(token, REFRESH_SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        token_type: str = payload.get("token_type")
        
        if user_id is None or token_type != "refresh":
            return None
            
        return TokenData(user_id=user_id)
    except JWTError:
        return None

async def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """Récupère l'utilisateur actuel à partir du token JWT"""
    from app.models.user import User
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants invalides",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        token_data = verify_token(token, credentials_exception)
        user = db.query(User).filter(User.id == token_data.user_id).first()
        
        if user is None:
            raise credentials_exception
            
        return user
    except Exception as e:
        # Log plus détaillé pour aider au débogage
        print(f"Erreur d'authentification: {str(e)}")
        raise credentials_exception
