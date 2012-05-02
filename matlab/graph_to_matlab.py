from collections import defaultdict

filename = "graph.txt"

class GraphData(object):
  def __init__(self):
    self.langs = dict()
    self.follows = defaultdict(list)
    self.p = dict()
    self.nodemap = dict()
    self.inv_nodemap = dict()
    self.n = 0 # No. of bilingual people with followers
    self.constants = dict()
    
  def sort_nodes(self):
    # Sort the node ids so that bilingual people
    # who have followers come first
    m = len(self.p)
    ids = range(1,m+1)
    # Find list of people who are bilingual
    is_bilingual = [ 1 if sum(self.langs[i]) == 2 else 0 for i in ids ]
    for i in ids:
      constants = list([0,0])
      for j in self.follows[i]:
        if is_bilingual[j-1] == 0: #Not bilingual
          assert (self.p[j] == 0 or self.p[j] == 1) #should be monolingual proportions
          constants[0] += self.langs[j][0]
          constants[1] += self.langs[j][1]
      self.constants[i] = constants
    # Find list of people who have followers
    followed = defaultdict(list)
    for i in ids:
      for j in self.follows[i]:
        followed[j].append(i)
    is_followed = [ 1 if len(followed[i]) >= 1 else 0 for i in ids ]
    # Sort_order first by having followers, and then by being bilingual
    sort_order = [ 2*x+y for x,y in zip(is_followed, is_bilingual) ] # descending
    self.n = sum( [ 1 for s in sort_order if s == 3 ] )
    sorted_ids = sorted( zip(ids,sort_order), key=lambda x: -x[1] )
    # Compute nodemap and its inverse
    self.nodemap = dict( [ (i,j) for j,(i,_) in zip(ids, sorted_ids) ] )
    self.inv_nodemap = dict( [ (j,i) for j,(i,_) in zip(ids, sorted_ids) ] )
    # Convert all to new numbering
    p = dict()
    langs = dict()
    follows = defaultdict(list)
    for i in ids:
      p[ self.nodemap[i] ] = self.p[i]
      langs[ self.nodemap[i] ] = self.langs[i]
      follows[ self.nodemap[i] ] = [ self.nodemap[j] for j in self.follows[i]]
    self.p = p
    self.langs = langs
    self.follows = follows
    
  def print_matlab(self):
    m = len(self.p)
    ids = range(1,m+1)
    print "langs = ["
    for i in ids:
      print self.langs[i][0],self.langs[i][1]
    print "]';"
    print
    print "follows = sparse(%d,%d);"%(self.n,m)
    for i in ids:
      for j in self.follows[i]:
        if j <= self.n: print "follows(%d,%d) = 1;"%(j,i)
    print
    print "p0 = [",
    for i in ids:
      print "%g"%self.p[i],
    print "]';"
    print
    print "nodemap = [",
    for i in ids:
      print self.inv_nodemap[i],
    print "]';"
    print
    print "constants = ["
    for i in ids:
      print "%g %g"%tuple(self.constants[i])
    print "]';"
    print

if __name__ == "__main__":
  data = GraphData()
  langsdict = { 'da':2, 'en':1 }
  with open(filename,"r") as f:
    for line in f:
      l = line.split(",")
      if l[0] == "N":
        id,proportion,langstr = l[1:]
        proportion = float(proportion)
        id = int(id)
        assert id == len(data.p)+1
        langs = list([0,0])
        for s in langstr.strip().split("|"):
          # print s
          if s == 'en':
            langs[0] = 1
          elif s == 'da':
            langs[1] = 1
        data.langs[id] = langs
        data.p[id] = proportion
      elif l[0] == "E":
        i,j = int(l[1]),int(l[2])
        data.follows[i].append(j)
  data.sort_nodes()
  data.print_matlab()
  