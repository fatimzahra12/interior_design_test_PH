from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status
from fastapi import Depends, HTTPException, status  # ← Ajouter Depends
from fastapi.security import OAuth2PasswordBearer
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
import database
import crud
import os

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production-2024")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Configuration de bcrypt - CORRIGÉE
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto"
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Vérifie un mot de passe"""
    try:
        # Limiter à 72 octets (limite bcrypt)
        if isinstance(plain_password, str):
            plain_password_bytes = plain_password.encode('utf-8')
            if len(plain_password_bytes) > 72:
                plain_password = plain_password_bytes[:72].decode('utf-8', errors='ignore')
        
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        print(f"❌ Erreur verify_password: {e}")
        return False

def get_password_hash(password: str) -> str:
    """Hash un mot de passe"""
    try:
        # S'assurer que c'est une string
        password = str(password)
        
        # Limiter à 72 octets (limite bcrypt)
        password_bytes = password.encode('utf-8')
        if len(password_bytes) > 72:
            # Tronquer proprement en évitant de couper un caractère UTF-8
            password = password_bytes[:72].decode('utf-8', errors='ignore')
            print(f"⚠️  Mot de passe tronqué à 72 octets")
        
        hashed = pwd_context.hash(password)
        print(f"✅ Mot de passe hashé avec succès")
        return hashed
    except Exception as e:
        print(f"❌ Erreur get_password_hash: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors du hachage du mot de passe: {str(e)}"
        )
    
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(database.get_db)
):
    """Récupère l'utilisateur actuellement connecté depuis le token"""
    email = verify_token(token)
    user = crud.get_user_by_email(db, email=email)
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utilisateur non trouvé"
        )
    
    return user

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Crée un token JWT"""
    try:
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=15)
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt
    except Exception as e:
        print(f"❌ Erreur create_access_token: {e}")
        raise HTTPException(
            status_code=500,
            detail="Erreur lors de la création du token"
        )

def verify_token(token: str) -> str:
    """Vérifie un token JWT et retourne l'email"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        
        if email is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials"
            )
        
        # S'assurer que email est une string
        return str(email)
        
    except JWTError as e:
        print(f"❌ Erreur verify_token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )
    except Exception as e:
        print(f"❌ Erreur inattendue verify_token: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials"
        )