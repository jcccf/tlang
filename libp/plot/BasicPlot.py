import matplotlib
import matplotlib.pyplot as plt

def colors(length):
  colors=[]
  c = matplotlib.cm.get_cmap('gist_rainbow')
  for i in range(length):
    colors.append(c(1.*i/length))
  return colors

# Plot y against log x (semi-log plot)
def plot_semilog(name, dict, xlabel='', ylabel='', title='', linetype='k'):
	plt.clf()
	if len(xlabel) > 0:
		plt.xlabel(xlabel)
	if len(ylabel) > 0:
		plt.ylabel(ylabel)
	if len(title) > 0:
		plt.title(title)
		
	dicty = zip(*sorted(dict.iteritems()))
	plt.semilogx(dicty[0], dicty[1], linetype)
	plt.savefig('../data/images/%s.eps' % name)
	
# Plot y against log x (semi-log plot)
def plot_multiline(name, dict_array, xlabel='', ylabel='', title='', linetypes=['b','r','g','k'], labels=[], xlog=None, ylim=None):
  plt.clf()
  if len(xlabel) > 0:
  	plt.xlabel(xlabel)
  if len(ylabel) > 0:
  	plt.ylabel(ylabel)
  if len(title) > 0:
  	plt.title(title)
  if xlog:
    plt.xscale('log', basex=xlog)
  if ylim:
    plt.ylim(ylim)
  for dicty, linetype, label in zip(dict_array, linetypes, labels): 
    dicty = zip(*sorted(dicty.iteritems()))
    plt.plot(dicty[0], dicty[1], linetype, label=label)
  plt.legend()
  plt.savefig('%s.eps' % name)

# Plot y against log x (semi-log plot)
def plot_twoscales(name, dict_array, xlabel='', ylabel='', title='', linetypes=['b','r','g','k'], labels=[], xlog=None, ylim=None):
  plt.clf()
  if len(xlabel) > 0:
  	plt.xlabel(xlabel)
  if len(ylabel) > 0:
  	plt.ylabel(ylabel)
  if len(title) > 0:
  	plt.title(title)
  if xlog:
    plt.xscale('log', basex=xlog)
  if ylim:
    plt.ylim(ylim)

  ax1 = plt.figure().add_subplot(111)  
  dicty1 = zip(*sorted(dict_array[0].iteritems()))
  dicty2 = zip(*sorted(dict_array[1].iteritems()))
  ax1.plot(dicty1[0], dicty1[1], linetypes[0], label=labels[0])
  for tl in ax1.get_yticklabels():
    tl.set_color(linetypes[0])
  ax1.set_ylabel(labels[0], color=linetypes[0])
  ax2 = ax1.twinx() 
  ax2.plot(dicty2[0], dicty2[1], linetypes[1], label=labels[1])
  for tl in ax2.get_yticklabels():
    tl.set_color(linetypes[1])
  ax2.set_ylabel(labels[1], color=linetypes[1])
  plt.savefig('%s.eps' % name)


# Plot log y against log x (log-log plot)
def plot_loglog(name, dict, xlabel='', ylabel='', title='', linetype='b'):
	plt.clf()
	if len(xlabel) > 0:
		plt.xlabel(xlabel)
	if len(ylabel) > 0:
		plt.ylabel(ylabel)
	if len(title) > 0:
		plt.title(title)

	dicty = zip(*sorted(dict.iteritems()))
	plt.loglog(dicty[0], dicty[1], linetype)
	plt.savefig('%s' % name)	
	
# Plot y against log x (semi-log plot)
def plot_log(name, dict, xlabel='', ylabel='', title='', linetype='k', log=2):
	plt.clf()
	if len(xlabel) > 0:
		plt.xlabel(xlabel)
	if len(ylabel) > 0:
		plt.ylabel(ylabel)
	if len(title) > 0:
		plt.title(title)
		
	dicty = zip(*sorted(dict.iteritems()))
	plt.xscale('log', basex=log)
	plt.plot(dicty[0], dicty[1], linetype)
	plt.savefig('../data/images/%s.eps' % name)