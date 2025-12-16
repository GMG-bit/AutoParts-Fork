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

# PASO 1: Instalar librerías del sistema necesarias para compilar Pillow, etc.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        libjpeg-dev \
        zlib1g-dev \
        libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# PASO 2: Instalamos dependencias de Python
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copiamos el resto del código fuente del proyecto
COPY . .


# ===============================================
# === ETAPA 2: PRODUCCIÓN (FINAL) ===
# Le daremos un nombre único a esta etapa para evitar el warning 'DuplicateStageName'
FROM python:3.11-slim as final

# Configuramos el entorno de producción
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
WORKDIR /usr/src/app

# PASO 3: Instalamos SÓLO las librerías de runtime necesarias (sin las -dev)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        libjpeg62-turbo \
        zlib1g \
        libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiamos las dependencias de Python y el código desde la etapa 'builder'
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/src/app /usr/src/app

# Expone el puerto
EXPOSE 8000

# Comando para correr la aplicación
# IMPORTANTE: Reemplaza 'nombre_de_tu_proyecto' con tu directorio de proyecto principal.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "nombre_de_tu_proyecto.wsgi:application"]