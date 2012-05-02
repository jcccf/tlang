import matplotlib
import matplotlib.pyplot as plt
import operator
from collections import Counter

def colors(length):
  colors=[]
  c = matplotlib.cm.get_cmap('gist_rainbow')
  for i in range(length):
    colors.append(c(1.*i/length))
  return colors
  
def smoothed_line(xy_list, sliding_window=10):
  xydict = {}
  xs, ys = zip(*xy_list)
  xmax = max(xs)
  for x, y in xy_list:
    for xreal in range(max(x-sliding_window/2, 0), min(x+sliding_window/2+1, xmax)):
      xydict.setdefault(xreal, []).append(y)
  xy2 = sorted([(x, sum(y)/len(y)) for x, y in xydict.iteritems()])
  xs2, ys2 = zip(*xy2)
  return (xs2, ys2) 

def histogram_plot(filename, xs, bins=1, normed=1, color='b', label='hello', ylim=None, xlim=None, xlabel=None, ylabel=None, histtype='stepfilled'):
  plt.clf()
  plt.figure().set_size_inches(6,4)
  n, bins, patches = plt.hist(xs, bins, normed=normed, histtype=histtype, rwidth=0.8, color=color, label=label)
  if xlabel:
    plt.xlabel(xlabel)
  if ylabel:
    plt.ylabel(ylabel)
  if ylim:
    plt.ylim(ylim)
  else:
    try:
      plt.ylim((0, max(n)*1.05))
    except:
      n_lim = max(max(ns) for ns in n) * 1.05
      plt.ylim((0, n_lim))
  if xlim:
    plt.xlim(xlim)
  plt.legend()
  plt.savefig('%s' % filename)
  return (n, bins, patches)

def activity_plot(filename, lists, labels):
  '''On individual lines, plot the activity of each list. The values in the list are typically times'''
  plt.clf()
  plt.figure().set_size_inches(20,10)
  ax = plt.subplot(111)
  ccolors = colors(len(lists))
  
  for i, (xs, label) in enumerate(zip(lists, labels)):
    ys = [i+1] * len(xs)
    ax.scatter(xs, ys, color=ccolors[i], label=label)
  plt.setp(ax.get_yticklabels(), visible=False)
  
  box = ax.get_position()
  ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])  
  from matplotlib.font_manager import FontProperties
  fontP = FontProperties()
  fontP.set_size('small')
  ax.legend(loc='center left', bbox_to_anchor=(1, 0.5), prop=fontP)
  
  plt.savefig('%s' % filename)

def scatter_plot(filename, xy_list, other_xy_lists=[], plot_lines=True, sliding_window=10, title=None):
  import numpy as np
  
  plt.clf()
  fig = plt.figure()
  fig.set_size_inches(20,10)
  ax = plt.subplot(111)
  
  # Plot smoothed lines for other lists
  if plot_lines:
    ccolors = colors(len(other_xy_lists))
    for i, listy in enumerate(other_xy_lists):
      oxs2, oys2 = smoothed_line(listy, sliding_window = sliding_window)
      ax.plot(oxs2, oys2, color=ccolors[i])
  
  # Plot scatter for xy_list
  xs, ys = zip(*xy_list)
  ax.scatter(xs, ys, marker='x', color='b')
  # ax.set_aspect(1.)
  
  # Plot smoothed line for xy_list
  if plot_lines:
    xs2, ys2 = smoothed_line(xy_list, sliding_window=sliding_window)
    ax.plot(xs2, ys2, 'k')
  
  from mpl_toolkits.axes_grid1 import make_axes_locatable
  divider = make_axes_locatable(ax)
  axHistx = divider.append_axes("top", 1.2, pad=0.1, sharex=ax)
  axHisty = divider.append_axes("right", 1.2, pad=0.1, sharey=ax)
  
  plt.setp(axHistx.get_xticklabels() + axHisty.get_yticklabels(), visible=False)

  binwidth = .5
  xmax = np.max(np.fabs(xs))
  ymax = np.max(np.fabs(ys))
  # xymax = np.max( [np.max(np.fabs(xs)), np.max(np.fabs(ys))] )
  #lim = ( int(xymax/binwidth) + 1) * binwidth
  limx = ( int(xmax/binwidth) + 1) * binwidth
  limy = ( int(ymax/binwidth) + 1) * binwidth
  #bins = np.arange(0, lim + binwidth, binwidth)
  binsx = np.arange(0, limx + binwidth, binwidth)
  binsy = np.arange(0, limy + binwidth, binwidth)
  axHistx.hist(xs, bins=binsx)
  axHisty.hist(ys, bins=binsy, orientation='horizontal')
  #axHistx.axis["bottom"].major_ticklabels.set_visible(False)
  for tl in axHistx.get_xticklabels():
      tl.set_visible(False)
  axHistx.set_yticks([0, 50, 100])
  #axHisty.axis["left"].major_ticklabels.set_visible(False)
  for tl in axHisty.get_yticklabels():
      tl.set_visible(False)
  axHisty.set_xticks([0, 50, 100])
  
  if title:
    fig.text(.5, .95, title, horizontalalignment='center')

  plt.savefig('%s' % filename)
  

def frequency_plots(filename, xs_list, normalize=False, color='b', labels=['Plot1'], title=None, ylim=None, xlim=None, xlabel=None, ylabel=None):
  '''Take lists of lists of values, create multiple frequency tables and plot multiple lines'''
  ccolors = colors(len(xs_list))
  plt.clf()
  plt.figure().set_size_inches(25,15)
  ax = plt.subplot(111)
  for i, xs in enumerate(xs_list):
    dik = Counter(xs)
    if normalize:
      diksum = sum(dik.values())
      dik = {k:float(v)/diksum for k,v in dik.iteritems()}
    dicty = zip(*sorted(dik.iteritems()))
    ax.plot(dicty[0], dicty[1], color=ccolors[i], label=labels[i])
    ax.scatter(max(dik, key=dik.get), dik[max(dik, key=dik.get)], color=ccolors[i])
  if xlabel:
    ax.xlabel(xlabel)
  if ylabel:
    ax.ylabel(ylabel)
  if ylim:
    plt.ylim(ylim)
  else:
    plt.ylim(ymin=0)
  if xlim:
    plt.xlim(xlim)
  if title:
    plt.title(title)
  box = ax.get_position()
  ax.set_position([box.x0, box.y0, box.width * 0.8, box.height])  
  from matplotlib.font_manager import FontProperties
  fontP = FontProperties()
  fontP.set_size('small')
  ax.legend(loc='center left', bbox_to_anchor=(1, 0.5), prop=fontP)
  plt.savefig('%s' % filename)

if __name__ == '__main__':
  # scatter_plot('hello.png', [(1,2), (1,3), (2,1), (2,5)])
  activity_plot('hello.png', [[1,2,3], [1,2,4]], ['hello', 'world'])