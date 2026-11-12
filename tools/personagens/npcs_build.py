# The village's three NPCs (docs/VILAREJO.md), same N64 recipe as the mutant (lowpoly.py): one joint table per
# character drives the rigid parts, the bones and the skin weights; 64 px painted face; a 2 s idle loop.
#   vendeiro    Seu Bento, the shopkeeper (items): stout, bald with a grey fringe, glasses, vest and apron
#   armeiro     Tenório, the weapons dealer: tall hunter in a poncho, wide hat, bandolier, shotgun on his back
#   benzedeira  Dona Firmina, the quest giver: old healer in black, headscarf and shawl, praying with a rosary,
#               candles at her feet
# Run: blender -b --factory-startup --python tools/personagens/npcs_build.py
#   -> blender/npcs/<name>.blend, godot_demo/models/characters/npc_<name>.glb, renders/npcs/npc_<name>_{front,34}.png
# Each NPC is its own file in npcs/ (built on tools/comum/npc_kit.py); this runs them all, in order.
import os, runpy

HERE = os.path.dirname(os.path.abspath(__file__))
NPCS = ['vendeiro', 'armeiro', 'benzedeira', 'mae', 'cida', 'bastiao', 'mascate']  # (mae: his mother in 1955, only in the opening's memory)

for who in NPCS:
    runpy.run_path(os.path.join(HERE, "npcs", who + ".py"), run_name="__main__")
