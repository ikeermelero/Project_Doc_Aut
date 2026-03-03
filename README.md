# 🤖 git-ollama-docs

Documenta automáticamente tus commits con **Ollama phi3** generando un `docs/DOCUMENTACION.html` bonito y navegable.

## ¿Cómo funciona?

Cada vez que haces `git commit -m "..."` el hook `post-commit` se activa y:

1. Lee la info del commit (hash, mensaje, archivos, estadísticas)
2. Te pregunta si quieres documentarlo
3. Si dices que sí, envía un prompt optimizado a Ollama phi3
4. Crea `docs/DOCUMENTACION.html` si no existe (con diseño oscuro moderno)
5. Inserta la nueva entrada con el análisis generado

## Instalación

```bash
# 1. Copia la carpeta a cualquier lugar
git clone <este-repo> git-ollama-docs

# 2. Entra en tu proyecto Git
cd tu-proyecto

# 3. Ejecuta el instalador
bash /ruta/a/git-ollama-docs/install.sh

# 4. Asegúrate de tener Ollama corriendo con phi3
ollama serve          # en otra terminal
ollama pull phi3      # si aún no lo tienes
```

## Instalación manual (sin script)

```bash
cp git-ollama-docs/hooks/post-commit .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

## Requisitos

- `git`
- `curl`
- `python3`
- [Ollama](https://ollama.ai) corriendo en `localhost:11434`
- Modelo `phi3` descargado: `ollama pull phi3`

## Optimizaciones para velocidad con phi3

El hook usa estos parámetros para maximizar la velocidad:
- `num_predict: 400` — respuestas cortas y precisas
- `temperature: 0.3` — menos aleatoriedad = más rápido
- `top_k: 20` — pool de tokens reducido
- `num_ctx: 1024` — ventana de contexto mínima necesaria
- `stream: false` — sin overhead de streaming

## Desinstalar

```bash
rm .git/hooks/post-commit
```
