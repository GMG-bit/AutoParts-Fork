# ========================
# ETAPA 1: BUILDER
# Usa una imagen liviana pero con Python y suficiente base para el build
# ========================
FROM python:3.11-slim as builder

# Define el directorio de trabajo
WORKDIR /usr/src/app

# Copia solo el archivo de requerimientos para aprovechar el cache
COPY requirements.txt .

# 4A: Actualiza la lista de paquetes.
# (Capas separadas para mejor caching y menor riesgo de timeout)
RUN apt-get update

# 4B: Instala las librerías de desarrollo para compilar dependencias de Python
# (ej. Pillow necesita libjpeg-dev, psycopg2 necesita libpq-dev)
RUN apt-get install -y --no-install-recommends \
        gcc g++ \
        libpq-dev \
        libjpeg-dev \
        zlib1g-dev \
        libwebp-dev \
    && rm -rf /var/lib/apt/lists/*

# 5: Instala las dependencias de Python
# Esto se hace en la etapa builder para que los archivos temporales se descarten
RUN pip install --no-cache-dir -r requirements.txt

# ========================
# ETAPA 2: FINAL
# Crea una imagen de producción limpia y ligera
# ========================
FROM python:3.11-slim as final

# Define el directorio de trabajo
WORKDIR /usr/src/app

# 3: Instala las librerías del sistema necesarias en PROD
# (Versiones runtime, no headers: libpq5, libjpeg62-turbo, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libpq5 \
        libjpeg62-turbo \
        zlib1g \
        libwebp7 \
    && rm -rf /var/lib/apt/lists/*

# 4: Copia las dependencias de Python desde la etapa 'builder'
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# 5: Copia el resto del código de la aplicación
COPY . .

# 6: Configura variables de entorno para producción (opcional)
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 7: Define el comando por defecto para iniciar la aplicación (ej. Gunicorn)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "your_project_name.wsgi:application"]