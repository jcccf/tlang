# -*- coding: utf-8 -*-
import networkx as nx, json, glob, pygraphviz as pgv
from collections import Counter
from mcolor import *

#
# Constants
#

USERS_DIR = "data/users"
LANGUAGES_DIR = "data/languages"
FOLLOWERS_DIR = "data/followers"
# lang_to_color = { "da":"#ff219e", "en":"#29f3f6", "nb":"#b9f438" }
lang_to_color = { "da":"#ff219e", "en":"#29f3f6" }

#
# Functions
#

def load_graph():
  g = nx.DiGraph()
  id_to_screen_name = {}

  # Load all users and get their language status if available
  print "Loading users and languages..."
  for filename in glob.glob("%s/*.txt" % USERS_DIR):
    # print filename
    # Load user info
    with open(filename, 'rb') as f:
      uinfo = json.loads(f.read())
      g.add_node(uinfo['screen_name'], id=uinfo['id'])
      id_to_screen_name[uinfo['id']] = uinfo['screen_name']
    # Attempt to load language frequencies for this user
    try:
      with open("%s/%s.txt" % (LANGUAGES_DIR, uinfo['id']), 'rb') as f:
        langs = json.loads(f.read())
        languages = { k:v for k, v in Counter([l['language'] for l in langs]).iteritems() if v > 9 }
        g.node[uinfo['screen_name']]['languages'] = languages
    except IOError:
      pass

  # Load follower edges and create edges if possible
  print "Loading edges..."
  for n, d in g.nodes_iter(data=True):
    with open("%s/%s.txt" % (FOLLOWERS_DIR, d['id']), 'rb') as f:
      followers = json.loads(f.read())
      for uid in followers['followers']:
        if uid in id_to_screen_name:
          g.add_edge(id_to_screen_name[uid], n)
      for uid in followers['friends']:
        if uid in id_to_screen_name:
          g.add_edge(n, id_to_screen_name[uid])
  return g

def graphviz_labels(A):
  A.edge_attr['color'] = '#50505050'
  A.node_attr['shape'] = 'circle'
  A.edge_attr['arrowsize'] = '0.5'
  A.node_attr['forcelabels'] = 'true'
  A.node_attr['fontname'] = 'Helvetica'
  A.node_attr['fontsize'] = '9'
  A.node_attr['style'] = 'filled'
  A.layout(prog="fdp")
  A.draw("graph_labels.svg")
  
def graphviz_neato(A):
  A.edge_attr['color'] = '#50505050'
  A.node_attr['shape'] = 'point'
  A.edge_attr['arrowsize'] = '0.5'
  A.layout(prog="neato")
  A.draw("graph.svg")

# Prepare PyGraphViz Graph
def generate_pygraphviz(g, remove_disconnected=True):
  A = nx.to_agraph(nx.DiGraph())

  print "Adding Nodes..."
  for n, data in g.nodes_iter(data=True):
    if 'languages' in data:
      langy = [x[0] for x in sorted(data['languages'].iteritems(), key=lambda x: -x[1])[:2]]
      colors = [lang_to_color[lang] for lang in langy if lang in lang_to_color]
      if len(colors) > 0:
        A.add_node(n, color=color_mix(*colors))
      else: # No languages of interest
        pass
    else: # No languages data at all
      pass

  print "Adding Edges..."
  node_hash = { n:True for n in A.nodes() }
  for n1, n2, data in g.edges_iter(data=True):
    if n1 in node_hash and n2 in node_hash:
      A.add_edge(n1, n2)
  
  if remove_disconnected is True:
    print "Removing disconnected nodes..."
    for n in A.nodes():
      if A.out_degree(n) == 0 and A.in_degree(n) == 0:
        A.remove_node(n)
  
  return A

if __name__ == '__main__':
  g = load_graph()
  A = generate_pygraphviz(g, remove_disconnected=True)
  graphviz_neato(A)
  A = generate_pygraphviz(g, remove_disconnected=True)
  graphviz_labels(A)