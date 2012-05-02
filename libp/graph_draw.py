from graph import *

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
