from graph import *
from collections import Counter
import numpy as np, math
import csv

# Plot scatter plot of switch ratio against proportion of tweets in the target language
def switch_to_prop(target="en"):
  xy_list = []
  for filename in glob.glob("%s/*.txt" % LANGUAGES_LDIG_DIR):
    with open(filename, 'rb') as f:
      langs = json.loads(f.read())
    counts, switches = language_info(langs)
    if counts is not None:
      target_prop = counts[target] if target in counts else 0.0
      xy_list.append((target_prop, switches))
  xy_list = sorted(xy_list, key=lambda x: x[0])
  with open('switch_to_prop.csv', 'wb') as f:
    writer = csv.writer(f)
    for xy in xy_list:
      writer.writerow(xy)
  DistributionPlot.scatter_plot('switch_to_prop.eps', xy_list, plot_lines=False)

# Estimate the deviation of the benefit function in the infinite consumption model from the optimal function value
def estimate_infinite_consumption_deviation_optimum():
  # Utility of a single player
  # p is the user's value, p_rest_list is a list of (the sum of friends' ps - p,total_friends) for each follower
  def utility(p,q_A,q_B,n):
    return n*(q_A*math.log(p*100)+q_B*math.log((1-p)*100))
  # def utility(p,q_A,q_B,n): # Log user utility
  #   return math.log(q_A*n)*math.log(p*100)+math.log(q_B*n)*math.log((1-p)*100)

  g = load_graph(remove_disconnected=True)
  g = filter_graph_by_language(g)
  g = add_language_ability_to_graph(g)
  
  with open('infdev.txt', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['p', 'utility', 'opt_p', 'opt_utility', 'epsilon'])
    for node, data in g.nodes_iter(data=True):
      if len(data['lang_ability']) > 1 and len(g.predecessors(node)) > 0:
        if 'en' in data['lang_freqs']:
          p = float(data['lang_freqs']['en']) / sum(data['lang_freqs'].values())
        else:
          p = 0.001 # Don't set this to zero to avoid log error
        if p == 1.0: p = 0.999 # Avoid log error    
        langs = Counter([tuple(sorted(g.node[m]['lang_ability'])) for m in g.predecessors(node)])
        q_A = float(langs[('en',)] + langs[('da','en')])/sum(langs.values())
        q_B = float(langs[('da',)] + langs[('da','en')])/sum(langs.values())
        opt_p = q_A/(q_A+q_B)
        # if q_A == 0.0: q_A = 0.0001
        # if q_B == 0.0: q_B = 0.0001
        # if q_A == 1.0: q_A = 0.9999
        # if q_B == 1.0: q_B = 0.9999
        # opt_p = math.log(q_A)/(math.log(q_A)+math.log(q_B))
        if opt_p == 0.0: opt_p = 0.001
        if opt_p == 1.0: opt_p = 0.999
        curr, opt = utility(p,q_A,q_B,1.0), utility(opt_p,q_A,q_B,1.0)
        writer.writerow([p, curr, opt_p, opt, 1.0-curr/opt])

# Plot deviations from estimate_infinite_consumption_deviation_optimum
def plot_infdev():
  with open('infdev.txt', 'r') as f:
    reader = csv.DictReader(f)
    ks = []
    for row in reader:
      ks.append(float(row['epsilon']))
    DistributionPlot.histogram_plot("infdevs.eps", ks, bins=30, normed=0, color='b', label='Distribution of $\epsilon$', ylim=None, xlim=[0,1.0], xlabel=None, ylabel=None, histtype='stepfilled')
    print "Mean deviation is", sum(ks)/len(ks)

# Estimate epsilon for each node in epsilon-Nash under the finite consumption model
def estimate_finite_consumption_epsilon_nash():
  # Utility of a single player
  # p is the user's value, p_rest_list is a list of (the sum of friends' ps - p,total_friends) for each follower
  def utility(p, p_rest_list):
    sum = 0
    for p_rest, total_num_ps in p_rest_list:
      sum += p / (p+p_rest) * math.log((p+p_rest)*100) + (1-p) / (total_num_ps-p-p_rest) * math.log((total_num_ps-p-p_rest)*100)
    return sum
  
  g = load_graph(remove_disconnected=True)
  g = filter_graph_by_language(g)
  g = add_language_ability_to_graph(g)
  
  # Load ps for all nodes
  for n, data in g.nodes_iter(data=True):
    if 'en' in data['lang_freqs']:
      p = float(data['lang_freqs']['en']) / sum(data['lang_freqs'].values())
    else:
      p = 0.001 # Don't set this to zero to avoid log error
    if p == 1.0: p = 0.999 # Avoid log error
    g.node[n]['p'] = p
  
  # For each node, estimate epsilon
  with open('epsilon.txt', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['p', 'utility', 'max_p', 'max_utility', 'epsilon'])
    for node, data in g.nodes_iter(data=True):
      if len(data['lang_ability']) > 1 and len(g.predecessors(node)) > 0:
        p, p_rest_list = data['p'], []
        # Load p_rest for each follower
        for m in g.predecessors(node): # for each follower
          succ = g.successors(m) # get people he follows
          ps = sum([g.node[x]['p'] for x in succ]) - p # get sum of ps for everyone except the original user
          p_rest_list.append((ps, len(succ)))
        # print p_rest_list
        current_utility = utility(p, p_rest_list)
        max_utility, max_p = current_utility, p
        for k in np.arange(0.001,1.0,0.001):
          new_u = utility(k, p_rest_list)
          if new_u > max_utility:
            max_utility, max_p = new_u, k
        writer.writerow([p, current_utility, max_p, max_utility, 1.0-current_utility/max_utility])
        print p, current_utility, max_p, max_utility

# Plot distribution of epsilon for estimate_finite_consumption_epsilon_nash
def plot_epsilons():
  with open('epsilon.txt', 'r') as f:
    reader = csv.DictReader(f)
    ks = []
    for row in reader:
      ks.append(float(row['epsilon']))
    DistributionPlot.histogram_plot("epsilons.eps", ks, bins=30, normed=1, color='b', label='Distribution of $\epsilon$', ylim=None, xlim=None, xlabel=None, ylabel=None, histtype='stepfilled')
    print "Mean epsilon is", sum(ks)/len(ks)

# Estimate r in the Immorlica bilingual diffusion model
# q is the utility of language B, 1-q is the utility of language A
def estimate_r_bilingual(q=0.5):
  g = load_graph(remove_disconnected=True)
  g = filter_graph_by_language(g)
  g = add_language_ability_to_graph(g)
  
  r_mins, r_maxs = [], []
  x, y = 0, 0
  for node, data in g.nodes_iter(data=True):
    langs = Counter([tuple(sorted(g.node[m]['lang_ability'])) for m in g.predecessors(node)])
    if len(data['lang_ability']) == 2 and len(langs) > 0:
      q_A = float(langs[('en',)] + langs[('da','en')])
      q_B = float(langs[('da',)] + langs[('da','en')])
      q_Aonly = float(langs[('en',)])
      q_Bonly = float(langs[('da',)])
      q_AB = float(langs[('da','en')])
      if len(data['lang_freqs']) == 1:
        # Monolingual : 0.5q_A or 0.5q_B > 0.5 - r
        if 'en' in data['lang_freqs']:
          r_mins.append(max(q,1-q)*q_AB + (1-q)*q_Aonly + q*q_Bonly - (1-q) * q_A)
        elif 'da' in data['lang_freqs']:
          r_mins.append(max(q,1-q)*q_AB + (1-q)*q_Aonly + q*q_Bonly - q * q_B)
        else:
          raise Exception()
        x += 1
      else:
        # Bilingual : 0.5 - r > 0.5p_A or 0.5p_B
        r_maxs.append(max(max(q,1-q)*q_AB + (1-q)*q_Aonly + q*q_Bonly - (1-q)*q_A, max(q,1-q)*q_AB + (1-q)*q_Aonly + q*q_Bonly - q*q_B))
        y += 1
    
  r_mins = sorted(r_mins)[int(0.05*len(r_mins)):]
  r_maxs = sorted(r_maxs)[:int(0.95*len(r_maxs))]
  DistributionPlot.histogram_plot("rs_%.3f.eps" % q, [r_mins, r_maxs], bins=50, normed=0, color=['b','r'], label=['$r_{min}$', '$r_{max}$'], ylim=None, xlim=[0, 20], xlabel=None, ylabel=None, histtype='step')
        
  print r_mins
  print r_maxs
  print "Bilingual but Tweet in 1", x, "Bilingual and Tweet in 2", y

# Estimate k's in the infinite consumption model
def estimate_ks_bilingual():
  def utility(p,q_A,q_B,n,k):
    #return math.sqrt(p*(q+q_bar))+math.sqrt((1-p)*(1-q))-k*p*(1-p)
    return n*(q_A*math.log(p)+q_B*math.log(1-p))-k*p*(1-p)
  # Load graph and filter by language
  g = load_graph(remove_disconnected=True)
  g = filter_graph_by_language(g)
  g = add_language_ability_to_graph(g)
  
  print len(g.nodes()), len(g.edges())
  
  unsupported, supported, monos = 0, 0, []
  with open('ks.txt', 'w') as f:
    writer = csv.writer(f)
    writer.writerow(['k', 'p', 'q_A', 'q_B', 'n', 'num_friends'])
    # For each node, determine p and q
    # Figure out k which maximizes function
    for node, data in g.nodes_iter(data=True):
      if len(data['lang_ability']) > 1:
        if 'en' in data['lang_freqs']:
          p = float(data['lang_freqs']['en']) / sum(data['lang_freqs'].values())
        else:
          p = 0.001 # TODO Adjust this!
        if p == 1.0:
          p = 0.999 # TODO Adjust this!
        langs = Counter([tuple(sorted(g.node[m]['lang_ability'])) for m in g.predecessors(node)])
        if sum(langs.values()) > 0:
          q_A = float(langs[('en',)] + langs[('da','en')])/sum(langs.values())
          q_B = float(langs[('da',)] + langs[('da','en')])/sum(langs.values())
          n = len(g.predecessors(node))
          if (q_A > q_B and p < float(q_A)/(q_A+q_B)) or (q_A < q_B and p > float(q_A)/(q_A+q_B)):
            unsupported += 1
          else:
            supported += 1      
            ks = []
            for k in np.arange(0, 100, 0.001):
              k = k / n
              if (p-0.01 > 0 and utility(p-0.01, q_A, q_B, 1.0, k) <= utility(p, q_A, q_B, 1.0, k)) and (p+0.01 < 1 and utility(p, q_A, q_B, 1.0, k) >= utility(p+0.01, q_A, q_B, 1.0, k)):
                ks.append(k)
            if len(ks) == 0:
              print "Did not find k for", p, q_A, q_B, n
            else:
              k = sum(ks)/len(ks)
              writer.writerow([k, p, q_A, q_B, n, len(g.successors(node))])
          print unsupported, supported
        else:
          print "No followers"
      else:
        monos.append(tuple(data['lang_freqs'].keys()))
    print "Unsupported Examples", unsupported # Which do not support the hypothesis that p must exceed 
    print "Supported", supported
    print "Monolinguals", Counter(monos)

# Plot distribution of ks for estimate_ks_bilingual
def plot_ks():
  with open('ks.txt', 'r') as f:
    reader = csv.DictReader(f)
    ks = []
    for row in reader:
      ks.append(float(row['k']))
    DistributionPlot.histogram_plot("ks.eps", ks, bins=30, normed=0, color='b', label='Distribution of $k$', ylim=None, xlim=None, xlabel=None, ylabel=None, histtype='stepfilled')
    

if __name__ == '__main__':
  # switch_to_prop()
  
  # estimate_ks_bilingual()
  # plot_ks()
  
  # estimate_r_bilingual(0.5)
  
  # estimate_finite_consumption_epsilon_nash()
  # plot_epsilons()
  
  estimate_infinite_consumption_deviation_optimum()
  plot_infdev()