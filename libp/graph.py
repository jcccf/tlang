# -*- coding: utf-8 -*-
import networkx as nx, json, glob, pygraphviz as pgv, csv
from collections import Counter
from mcolor import *

#
# Constants
#

USERS_DIR = "data/users"
LANGUAGES_LDIG_DIR = "data/languages_ldig"
FOLLOWERS_DIR = "data/followers"
valid_langs = ["da", "en"]
lang_to_color = { "da":"#ff219e", "en":"#29f3f6" }
# lang_to_color = { "da":"#ff219e", "en":"#29f3f6", "nb":"#b9f438" }

#
# Functions
#

def load_graph(remove_disconnected=True):
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
      with open("%s/%s.txt" % (LANGUAGES_LDIG_DIR, uinfo['id']), 'rb') as f:
        langs = json.loads(f.read())
        languages = { k:v for k, v in Counter(langs).iteritems() if v > 5 }
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
          
  if remove_disconnected is True:
    print "Removing disconnected nodes..."
    for n in g.nodes():
      if g.out_degree(n) == 0 and g.in_degree(n) == 0:
        g.remove_node(n)
  
  return g

def filter_graph_by_language(g):
  print "Filtering by valid languages..."
  g2 = nx.DiGraph()
  n2id = {}
  for n, data in g.nodes_iter(data=True):
    if 'languages' in data:
      langy = [x[0] for x in sorted(data['languages'].iteritems(), key=lambda x: -x[1])[:2]]
      langs = sorted([l for l in langy if l in valid_langs])
      if len(langs) > 0:
        g2.add_node(n, id=data['id'], languages=langs)
        n2id[n] = True
  # Make edges between nodes that have languages
  for n1, n2 in g.edges_iter():
    if n1 in n2id and n2 in n2id:
      g2.add_edge(n1, n2)
  return g2

def graphviz_labels(A, filename):
  print "Preparing graph with labels..."
  A.edge_attr['color'] = '#50505050'
  A.node_attr['shape'] = 'circle'
  A.edge_attr['arrowsize'] = '0.3'
  A.node_attr['forcelabels'] = 'true'
  A.node_attr['fontname'] = 'Helvetica'
  A.node_attr['fontsize'] = '9'
  A.node_attr['style'] = 'filled'
  A.layout(prog="fdp")
  A.draw(filename)
  
def graphviz(A, filename):
  print "Preparing graph..."
  A.edge_attr['color'] = '#50505050'
  A.node_attr['shape'] = 'point'
  A.edge_attr['arrowsize'] = '0.3'
  A.layout(prog="fdp")
  A.draw(filename)

# Prepare PyGraphViz Graph
def generate_pygraphviz(g, clustering=True):
  A = nx.to_agraph(nx.DiGraph())

  print "Adding nodes..."
  clusters = {}
  for n, data in g.nodes_iter(data=True):
    colors = [lang_to_color[lang] for lang in data['languages']] # Colors for languages of interest
    clusters.setdefault(tuple(sorted(colors)), []).append(n)
    A.add_node(n, color=color_mix(*colors))

  # Cluster
  if clustering is True:
    for i, (k, v) in enumerate(clusters.iteritems()):
      A.subgraph(nbunch=v, name="cluster%d" % i, color="invis")

  print "Adding edges..."
  for n1, n2 in g.edges_iter():
    A.add_edge(n1, n2)
  
  return A

def graph_with_lang_to_csv(g, filename):
  n2id, n2id_counter = {}, 1
  with open(filename, 'w') as f:
    writer = csv.writer(f)
    for n, data in g.nodes_iter(data=True):
      if n not in n2id:
        n2id[n] = n2id_counter
        n2id_counter += 1
      writer.writerow(["N", n2id[n], "|".join(data['languages'])])
    for n1, n2 in g.edges_iter():
      if n1 in n2id and n2 in n2id:
        writer.writerow(["E", n2id[n1], n2id[n2]])

def graph_betweenness(g):
  print "Computing betweenness centrality..."
  bc = nx.betweenness_centrality(g, normalized=True)
  print "Computing eigenvector centrality..."
  ec = nx.eigenvector_centrality(g)
  bc_hash, ec_hash = {}, {}
  for n, b in bc.iteritems():
    bc_hash.setdefault(tuple(g.node[n]['languages']), []).append(b)
  for n, b in ec.iteritems():
    ec_hash.setdefault(tuple(g.node[n]['languages']), []).append(b)
  return (bc_hash, ec_hash)

def graph_degree(g):
  print "Computing degree centrality..."
  ac = nx.degree_centrality(g)
  bc = nx.in_degree_centrality(g)
  ec = nx.out_degree_centrality(g)
  ac_hash, bc_hash, ec_hash = {}, {}, {}
  for n, b in ac.iteritems():
    ac_hash.setdefault(tuple(g.node[n]['languages']), []).append(b)
  for n, b in bc.iteritems():
    bc_hash.setdefault(tuple(g.node[n]['languages']), []).append(b)
  for n, b in ec.iteritems():
    ec_hash.setdefault(tuple(g.node[n]['languages']), []).append(b)
  return (ac_hash, bc_hash, ec_hash)

if __name__ == '__main__':
  g = load_graph(remove_disconnected=True)
  g = filter_graph_by_language(g)
  # bc, ec = graph_betweenness(g)
  ac, bc, ec = graph_degree(g)
  for k, v in ac.iteritems():
    print k, sum(v)/len(v)
  for k, v in bc.iteritems():
    print k, sum(v)/len(v)
  for k, v in ec.iteritems():
    print k, sum(v)/len(v)
  # graph_with_lang_to_csv(g, 'graph.txt')
  # A = generate_pygraphviz(g, clustering=True)
  # graphviz(A, "graph.svg")
  # A = generate_pygraphviz(g)
  # graphviz_labels(A, "graph_labels.svg")