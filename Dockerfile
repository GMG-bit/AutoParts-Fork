# ===============================================
# === ETAPA 1: BUILDER (Compilación e Instalación de Dependencias) ===
# Usa una imagen base Python 3.11 ligera
FROM python:3.11-slim as builder

# Configuramos el entorno de Python
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# Copiamos solo el archivo de requerimientos
COPY requirements.txt .

# PASO 1: Instalar librerías del sistema (más ligeras que build-essential)
# Incluye compiladores (gcc/g++) y librerías de desarrollo para Pillow (libjpeg, zlib, libwebp) y Psycopg2 (libpq).
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gcc \
        g++ \
        libpq-dev \
        libjpeg-dev \
        zlib1g-dev \
        libwebp-dev \
    # Limpiamos los archivos de lista para minimizar el tamaño de esta capa
    && rm -rf /var/lib/apt/lists/*

# PASO 2: Instalamos dependencias de Python (aquí se instala Jazzmin y Pillow)
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copiamos el resto del código fuente del proyecto
COPY . .


# ===============================================
# === ETAPA 2: PRODUCCIÓN (Final) ===
# Usamos la misma imagen base limpia para minimizar el tamaño
FROM python:3.11-slim as final

# Configuramos el entorno
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# PASO 3: Instalamos SÓLO las librerías de runtime necesarias (sin las -dev)
# Esto asegura que el código compilado de Pillow y Psycopg2 se ejecute.
# Usamos los paquetes sin '-dev' (excepto para libwebp, donde usamos la versión genérica de runtime)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        libjpeg62-turbo \
        zlib1g \
        libwebp7 \
    && rm -rf /var/lib/apt/lists/*

# Copiamos las dependencias de Python y el código desde la etapa 'builder'
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/src/app /usr/src/app

# Expone el puerto por defecto de Django/Gunicorn
EXPOSE 8000

# Comando para correr la aplicación (usa Gunicorn en producción)
# IMPORTANTE: Reemplaza 'nombre_de_tu_proyecto' con el nombre de tu directorio de proyecto principal.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "nombre_de_tu_proyecto.wsgi:application"]