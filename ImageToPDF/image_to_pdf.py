import subprocess
import sys

# Instala o reportlab se nao estiver disponivel
try:
    from reportlab.platypus import SimpleDocTemplate, Image
except ImportError:
    print("Instalando reportlab...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "reportlab"])
    from reportlab.platypus import SimpleDocTemplate, Image

####################################################################################

# Image to PDF Converter
from reportlab.platypus import SimpleDocTemplate, Image
from reportlab.lib.pagesizes import A4
from pathlib import Path

PASTA_FOTOS = Path(r"C:\fotos") # ou Path(r"\home\usuario\fotos") no Linux

MARGEM = 40
MAX_WIDTH = 430
MAX_HEIGHT = 650

arquivos = list(PASTA_FOTOS.glob("*.jpg")) + \
           list(PASTA_FOTOS.glob("*.jpeg")) + \
           list(PASTA_FOTOS.glob("*.png"))

if not arquivos:
    print("Nenhuma imagem encontrada.")
    exit()

for imagem in arquivos:

    pdf = imagem.with_suffix(".pdf")

    print(f"Convertendo: {imagem.name}")

    doc = SimpleDocTemplate(
        str(pdf),
        pagesize=A4,
        rightMargin=MARGEM,
        leftMargin=MARGEM,
        topMargin=MARGEM,
        bottomMargin=MARGEM
    )

    doc.title = imagem.stem + " - Image to PDF Converter"

    img = Image(str(imagem))

    escala = min(
        MAX_WIDTH / img.imageWidth,
        MAX_HEIGHT / img.imageHeight
    )

    img.drawWidth = img.imageWidth * escala
    img.drawHeight = img.imageHeight * escala

    doc.build([img])

print("Conversão concluída!")
