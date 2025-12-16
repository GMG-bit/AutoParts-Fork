# === ETAPA 1: BUILDER y PRUEBAS ===
# Usamos una imagen base con Python
FROM python:3.11-slim as builder

# Configuramos el entorno
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# Copiamos solo el archivo de requerimientos para aprovechar el cache de Docker
COPY requirements.txt .

# Instalamos dependencias
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copiamos el resto del código fuente
COPY . .

# Comando de prueba que GitHub Actions ejecutará (Asegúrate de tener un script 'run_tests.sh' o similar)
# Por ejemplo, puedes cambiar esto por RUN python manage.py test o RUN pytest
# En este ejemplo, solo preparamos la imagen para el paso de pruebas en el workflow.

# === ETAPA 2: PRODUCCIÓN (FINAL) ===
# Imagen final más limpia y pequeña
FROM python:3.11-slim

# Configuramos el entorno de producción
ENV PYTHONDONTWRITEBYTECODE 1
# ===============================================
# === ETAPA 1: BUILDER y PRUEBAS (Instalación) ===
# Imagen base con Python 3.11 para compatibilidad
FROM python:3.11-slim as builder

# Configuramos el entorno y el directorio de trabajo
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# Copiamos solo el archivo de requerimientos
COPY requirements.txt .

# PASO CRUCIAL 1: Instalamos librerías del sistema necesarias 
# para compilar Pillow, psycopg2 (si usas Postgres) y otras dependencias binarias.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        libjpeg-dev \
        zlib1g-dev \
        libwebp-dev \
    # Limpiamos los archivos de lista para mantener la imagen pequeña
    && rm -rf /var/lib/apt/lists/*

# PASO CRUCIAL 2: Instalamos dependencias de Python (incluyendo jazzmin, Pillow)
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copiamos el resto del código fuente del proyecto
COPY . .


# ===============================================
# === ETAPA 2: PRODUCCIÓN (FINAL) ===
# Usamos la misma imagen base limpia, pero solo con las librerías necesarias para correr
FROM python:3.11-slim

# Configuramos el entorno de producción
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# Importante: Las imágenes 'slim' no tienen las librerías base para PostgreSQL (libpq.so).
# Debemos reinstalar solo las librerías necesarias del sistema, no las herramientas de desarrollo.
RUN apt-get update && \
    # Instalar librerías de runtime (como las necesarias para psycopg2 y Pillow)
    apt-get install -y --no-install-recommends \
        libpq5 \
        libjpeg62-turbo \
        zlib1g \
        libwebp6 \
    && rm -rf /var/lib/apt/lists/*

# Copiamos las dependencias de Python y el código desde la etapa 'builder'
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/src/app /usr/src/app

# Expone el puerto por defecto de Django/Gunicorn
EXPOSE 8000

# Comando para correr la aplicación (usa Gunicorn en producción)
# IMPORTANTE: Reemplaza 'nombre_de_tu_proyecto' con el nombre de tu directorio de proyecto principal.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "nombre_de_tu_proyecto.wsgi:application"]