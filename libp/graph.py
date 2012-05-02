# -*- coding: utf-8 -*-
import networkx as nx, json, glob, pygraphviz as pgv, csv
from collections import Counter
from mcolor import *
from plot import *
from graph_draw import *

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

# Return amount of switching and language proportions
# Switching is the number of times the language changes as we go through the array
# If proportional is true, return fractions instead of absolute numbers
def language_info(lang_array, proportional=True):
  langs = [l for l in lang_array if l in valid_langs]
  lang_counts = Counter(langs)
  if len(langs) > 0:
    prev_lang, switches = langs[0], 0
    for l in langs:
      if l != prev_lang:
        switches += 1
        prev_lang = l
    if proportional is True:
      if switches > 0:
        switches /= (len(langs)-1.0) # Switch ratio - # of switches to total number of possible switches
      lang_counts = { k : float(v)/len(langs) for k, v in lang_counts.iteritems() }
    return (lang_counts, switches)
  else:
    return (None, None)

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

# Filters graph to contain only languages in the variable valid_langs
# Adds 'languages' key for each node (array of languages node uses in tweets)
# Adds 'lang_freqs' key for each node (hash of language > # of tweets in that language)
def filter_graph_by_language(g):
  print "Filtering by valid languages..."
  g2 = nx.DiGraph()
  n2id = {}
  for n, data in g.nodes_iter(data=True):
    if 'languages' in data:
      langy = [x for x in sorted(data['languages'].iteritems(), key=lambda x: -x[1])[:2]]
      langfreqs = {l:c for l,c in langy if l in valid_langs}
      langs = sorted([l for l,c in langy if l in valid_langs])
      if len(langs) > 0:
        g2.add_node(n, id=data['id'], languages=langs, lang_freqs=langfreqs)
        n2id[n] = True
  # Make edges between nodes that have languages
  for n1, n2 in g.edges_iter():
    if n1 in n2id and n2 in n2id:
      g2.add_edge(n1, n2)
  return g2

# Adds 'lang_ability' key for each node (array of languages a node knows)
def add_language_ability_to_graph(g):
  print "Adding language ability..."
  for n, data in g.nodes_iter(data=True):
    # Among monolingual friends, if more than 5 speak some language, add it
    ability = data['languages']
    monos = []
    for m in g.successors(n):
      if len(g.node[m]['languages']) == 1:
        monos.append(g.node[m]['languages'][0])
    monos = Counter(monos)
    for k, v in monos.iteritems():
      if v > 5 and k not in ability:
        ability.append(k)
        # print "Adding! ", k
    ability = sorted(ability)
    g.node[n]['lang_ability'] = ability
  return g

def graph_with_lang_to_csv(g, filename):
  n2id, n2id_counter = {}, 1
  with open(filename, 'w') as f:
    writer = csv.writer(f)
    for n, data in g.nodes_iter(data=True):
      if n not in n2id:
        n2id[n] = n2id_counter
        n2id_counter += 1
      if 'en' in data['lang_freqs']:
        p = float(data['lang_freqs']['en']) / sum(data['lang_freqs'].values())
      else:
        p = 0.0
      writer.writerow(["N", n2id[n], p, "|".join(data['lang_ability'])])
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
  g = add_language_ability_to_graph(g)
  

  # bc, ec = graph_betweenness(g)
  # for k, v in bc.iteritems():
  #   print k, sum(v)/len(v)
  # for k, v in ec.iteritems():
  #   print k, sum(v)/len(v)
  # 
  # ac, bc, ec = graph_degree(g)
  # for k, v in ac.iteritems():
  #   print k, sum(v)/len(v)
  # for k, v in bc.iteritems():
  #   print k, sum(v)/len(v)
  # for k, v in ec.iteritems():
  #   print k, sum(v)/len(v)
  
  graph_with_lang_to_csv(g, 'graph.txt')
  # A = generate_pygraphviz(g, clustering=True)
  # graphviz(A, "graph.svg")
  # A = generate_pygraphviz(g)
  # graphviz_labels(A, "graph_labels.svg")