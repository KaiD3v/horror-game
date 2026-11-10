# Where everything the tools read and write lives, from the project root (this file is tools/comum/paths.py).
# Every tool imports this instead of writing paths of its own:
#   import os, sys; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "comum"))
#   import paths
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TOOLS = os.path.join(ROOT, "tools")
GODOT = os.path.join(ROOT, "godot_demo")                      # the Godot project
CHARACTERS = os.path.join(GODOT, "models", "characters")       # protagonista, monster, enfermeira, npc_<who> .glb
LEVELS = os.path.join(GODOT, "models", "levels")               # vilarejo, armaria, venda, capela .glb
TEXTURES = os.path.join(GODOT, "textures")                     # scenery and paper textures
SOUNDS = os.path.join(GODOT, "sounds")                         # what the game plays (.wav)
FONTS = os.path.join(GODOT, "ui", "fonts")
BLEND = os.path.join(ROOT, "blender")                          # the .blend files the build scripts save
AUDIO_SOURCES = os.path.join(ROOT, "audio_fontes")             # ElevenLabs downloads, the old synthesized set
RENDERS = os.path.join(ROOT, "renders")                        # preview renders and review sheets


def out(*parts):
    """A path under ROOT for a file about to be written; its folder is created."""
    p = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    return p


def character(name):
    return out("godot_demo", "models", "characters", name + ".glb")


def level(name):
    return out("godot_demo", "models", "levels", name + ".glb")


def blend(kind, name):
    """kind: personagens, npcs, cenarios."""
    return out("blender", kind, name + ".blend")


def render(*parts):
    return out("renders", *parts)
