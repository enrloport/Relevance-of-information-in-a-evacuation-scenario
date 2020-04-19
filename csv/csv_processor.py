#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar  5 18:31:57 2020

@author: Enrique J. López Ortiz
"""
import datetime
import csv
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import scipy.stats as stats


# Create some dictionaries for the content of every file 
file0 = "files/evacuation_scenario:app-T-F,shooting-T-F,peace-150-600,visib-0,sound-0.csv"
dic__mod_0__app_1__peacefuls = {'name': 'mod_0 - app_1 - peacefuls'}
dic__mod_0__app_0__peacefuls = {'name': 'mod_0 - app_0 - peacefuls'}

file1 = "files/evacuation_scenario:app-T-F,shooting-T-F,peace-150-600,visib-1,sound-1.csv"
dic__mod_1__app_1__peacefuls = {'name': 'mod_1 - app_1 - peacefuls'}
dic__mod_1__app_0__peacefuls = {'name': 'mod_1 - app_0 - peacefuls'}

file2 = "files/evacuation_scenario app-T-F,attacker-speed-0.6-1.5,shooting-T,peace-350,mods-1.csv"
dic__mod_1__app_1__attackers_speed = {'name': 'mod_1 - app_1 - attackers_speed'}
dic__mod_1__app_0__attackers_speed = {'name': 'mod_1 - app_0 - attackers_speed'}

file3 = "files/evacuation_scenario app-T-F,leaders-percent-0-1,shooting-T,peace-350,mods-1.csv"
dic__mod_1__app_1__leaders = {'name': 'mod_1 - app_1 - leaders'}
dic__mod_1__app_0__leaders = {'name': 'mod_1 - app_0 - leaders'}

file4 = "files/evacuation_scenario app-T-F,rooms-T-F,shooting-T,peace-350,visib-0,sound-0.csv"
dic__mod_0__app_1__rooms_1 = {'name': 'mod_0 - app_1 - rooms_1'}
dic__mod_0__app_1__rooms_0 = {'name': 'mod_0 - app_1 - rooms_0'}
dic__mod_0__app_0__rooms_1 = {'name': 'mod_0 - app_0 - rooms_1'}
dic__mod_0__app_0__rooms_0 = {'name': 'mod_0 - app_0 - rooms_0'}

file5 = "files/evacuation_scenario app-T-F,rooms-T-F,shooting-T,peace-350,visib-1,sound-1.csv"
dic__mod_1__app_1__rooms_1 = {'name': 'mod_1 - app_1 - rooms_1'}
dic__mod_1__app_1__rooms_0 = {'name': 'mod_1 - app_1 - rooms_0'}
dic__mod_1__app_0__rooms_1 = {'name': 'mod_1 - app_0 - rooms_1'}
dic__mod_1__app_0__rooms_0 = {'name': 'mod_1 - app_0 - rooms_0'}
 


# Every single file of each csv file will became into an instance of the class simulation. 
class simulation:

    def __init__ (self, shooting, num_p, v_mod, s_mod, a_s, l_p, s, na_k,a_k,t_k, na_a,a_a,t_a, na_i,a_i,t_i, na_r,a_r,t_r, map_with_rooms):
            
        self.shooting         = True if shooting == 'true' else False    
        self.peacefuls        = int(num_p)
        self.visib_mod        = float(v_mod)
        self.sound_mod        = float(s_mod)
        self.attacker_speed   = float(a_s)
        self.leaders_perc     = float(l_p)
        self.ticks            = int(s)
        self.secure_rooms     = True if map_with_rooms == 'true' else False
        
        self.not_app_killed   = int(na_k)
        self.app_killed       = int(a_k)
        self.total_killed     = int(t_k)
        
        self.not_app_accident = int(na_a)
        self.app_accident     = int(a_a)
        self.total_accident   = int(t_a)
        
        self.not_app_room     = int(na_i)
        self.app_room         = int(a_i)
        self.total_room       = int(t_i)
        
        self.not_app_rescued  = int(na_r)
        self.app_rescued      = int(a_r)
        self.total_rescued    = int(t_r)
    
    def __str__(self):
        res = "Shooting: " + str(self.shooting) + " ,Peacefuls: " + str(self.peacefuls) + " ,Ticks: " + str(self.ticks) + " ,App killed: " + str(self.app_killed) + " ,Not App killed: " + str(self.not_app_killed) + " ,Total killed: " + str(self.total_killed) + " ,App rescued: " + str(self.app_rescued) + " ,Not App rescued: " + str(self.not_app_rescued) + " ,Total rescued: " + str(self.total_rescued) + " ,App accident: " + str(self.app_accident) + " ,Not App accident: " + str(self.not_app_accident) + " ,Total accident: " + str(self.total_accident) + " ,App secure room: " + str(self.app_room) + " ,Not App secure room: " + str(self.not_app_room) + " ,Total secure room: " + str(self.total_room)
        return res
    
    def count_not_app(self):
        return self.not_app_killed + self.not_app_accident + self.not_app_room + self.not_app_rescued
    
    def count_app(self):
        return self.app_killed + self.app_accident + self.app_room + self.app_rescued


# This function reads the files and populate de dictionaries
def read_file(file):
    dic = {
         file0 : (dic__mod_0__app_1__peacefuls, dic__mod_0__app_0__peacefuls)
        ,file1 : (dic__mod_1__app_1__peacefuls, dic__mod_1__app_0__peacefuls)
        ,file2 : (dic__mod_1__app_1__attackers_speed, dic__mod_1__app_0__attackers_speed)
        ,file3 : (dic__mod_1__app_1__leaders, dic__mod_1__app_0__leaders)
        ,file4 : (dic__mod_0__app_1__rooms_1, dic__mod_0__app_0__rooms_1, dic__mod_0__app_1__rooms_0, dic__mod_0__app_0__rooms_0)
        ,file5 : (dic__mod_1__app_1__rooms_1, dic__mod_1__app_0__rooms_1, dic__mod_1__app_1__rooms_0, dic__mod_1__app_0__rooms_0 )
        }
    dic_app     = dic[file][0]
    dic_not_app = dic[file][1]
    try:
        dic_app_not_rooms     = dic[file][2]
        dic_not_app_not_rooms = dic[file][3]
    except:
        pass
   
    with open(file, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            try:
                # print('hola',row)
                if row[1]== 'true':
                    if row[36] == 'true':
                        dic_app[int(row[0])] = simulation( row[2], row[3], row[4], row[5], row[10], row[12], row[23]
                                            , row[24], row[25], row[26]
                                            , row[27], row[28], row[29]
                                            , row[30], row[31], row[32]
                                            , row[33], row[34], row[35], row[36]
                                            )
                    else:
                        dic_app_not_rooms[int(row[0])] = simulation( row[2], row[3], row[4], row[5], row[10], row[12], row[23]
                                            , row[24], row[25], row[26]
                                            , row[27], row[28], row[29]
                                            , row[30], row[31], row[32]
                                            , row[33], row[34], row[35], row[36]
                                            )
                        
                else:
                    if row[36] == 'true':
                        dic_not_app[int(row[0])] = simulation( row[2], row[3], row[4], row[5], row[10], row[12], row[23]
                                            , row[24], row[25], row[26]
                                            , row[27], row[28], row[29]
                                            , row[30], row[31], row[32]
                                            , row[33], row[34], row[35], row[36]
                                            )
                    else:
                        dic_not_app_not_rooms[int(row[0])] = simulation( row[2], row[3], row[4], row[5], row[10], row[12], row[23]
                                            , row[24], row[25], row[26]
                                            , row[27], row[28], row[29]
                                            , row[30], row[31], row[32]
                                            , row[33], row[34], row[35], row[36]
                                            )
                        
            except:
                pass      


#  This function returns all simulations in a dictionary satisfying some conditions 
#  result options: 'rescued', 'killed', 'room', 'accident'
#  targets options: 'both', 'app', 'not_app'
#  criteria options: ('attacker_speed', Integer number ), ('leaders_percentage', Integer number )
def list_by (dic, num_peac, result='rescued', targets = 'both', shoot=True, normalized=True, criteria=('',-1) ):
    res = []  
    
    keys = sorted( filter( lambda x: isinstance(x, int) , dic.keys()) ) 
    
    def select(elem):        
        if result == 'rescued':
            aux_app     = elem.app_rescued 
            aux_not_app = elem.not_app_rescued
            aux_total   = elem.total_rescued
        elif result == 'killed':
            aux_app     = elem.app_killed 
            aux_not_app = elem.not_app_killed
            aux_total   = elem.total_killed
        elif result == 'room':
            aux_app     = elem.app_room 
            aux_not_app = elem.not_app_room
            aux_total   = elem.total_room
        elif result == 'accident':
            aux_app     = elem.app_accident 
            aux_not_app = elem.not_app_accident
            aux_total   = elem.total_accident
        return aux_app, aux_not_app, aux_total
    
    def filter_aux(elem, criteria):
        if criteria == ('',-1):
            return True
        elif criteria[0] == 'attacker_speed':
            return elem.attacker_speed == criteria[1]
        elif criteria[0] == 'leaders_percentage':
            return elem.leaders_perc == criteria[1]
    
    if num_peac == 0:
        for k in keys:
            if dic[k].shooting == shoot and filter_aux(dic[k], criteria):
                normal = dic[k].peacefuls if normalized else 1
                res.append(select(dic[k])[2] / normal )            
    elif targets == 'app':
        for k in keys:
            if dic[k].shooting == shoot and dic[k].peacefuls == num_peac and filter_aux(dic[k], criteria):
                normal = dic[k].count_app if normalized else 1                    
                res.append(select(dic[k])[0] / normal )            
    elif targets == 'not_app':
        for k in keys:
            if dic[k].shooting == shoot and dic[k].peacefuls == num_peac and filter_aux(dic[k], criteria):
                normal = dic[k].count_app if normalized else 1
                res.append(select(dic[k])[1] / normal ) 
    else:
        for k in keys:
            if dic[k].shooting == shoot and dic[k].peacefuls == num_peac and filter_aux(dic[k], criteria):
                normal = dic[k].peacefuls if normalized else 1
                res.append(select(dic[k])[2] / normal )            
    return res
    

    
#  Given a dictionary and a target result, this function plots a simple histogram
#  results options: 'rescued', 'killed', 'room', 'accident'
def histogram (dic=dic__mod_0__app_1__peacefuls, num_peac=0, shoot=True, result='rescued', with_app = 'both', normalized=False, save_file=None, criteria=('',-1) ):
    
    main_title  = dic['name']
    if 'peacefuls' in dic['name']:
        main_title += '\nPeacefuls: From 150 to 600' if num_peac == 0 else '\nPeacefuls: ' + str(num_peac)
        main_title += ', Atck-speed: 0.5, Leaders-percent: 0.2'
    elif 'leaders' in dic['name']:
        main_title += '\nPeacefuls: 350, Atck-speed: 0.5'
        main_title += ', Leaders-percent: From 0 to 1' if criteria[1] == -1 else ', Leaders-percent: ' + str(criteria[1])
    else:
        main_title += '\nPeacefuls: 350, '
        main_title += 'Atck-speed: From 0.6 to 1.5' if criteria[1] == -1 else 'Atck-speed: ' + str(criteria[1])
        main_title += ', Leaders-percent: 0.2'
        
        
    main_title += ', Shooting' if shoot == True else ', Melee\n\n'
    
    h = list_by(dic, num_peac, result, with_app, shoot, normalized, criteria )
    h.sort()
    hmean = np.mean(h)
    hstd = np.std(h) 
    hstd = hstd if hstd > 0 else 0.6
    pdf = stats.norm.pdf(h, hmean, hstd)
    plt.suptitle(main_title, y = 1.05)
    plt.title(str.upper(result) + ' -> Mean: ' + str( "{0:.3f}".format(hmean) ) + ', Std: ' + str( "{0:.3f}".format(hstd) ) )
    plt.plot(h, pdf, '-o')
    plt.hist(h, density=True)
    
    if save_file:
        t=str(datetime.datetime.now())[:-7]
        file_type = t + '.' + save_file
        plt.savefig('../img/histogram_'+file_type , bbox_inches='tight', pad_inches=0.3)
    plt.show()




    
# Given a dictionary, this function plots the histograms for rescued, killed, secure-rooms and accident 
def show_histograms (dic, num_peac=0, with_app = 'both', shoot=True, normalized=False, save_file=None, criteria=('',-1)):
    
    main_title  = dic['name']
    if 'peacefuls' in dic['name']:
        main_title += '\nPeacefuls: From 150 to 600' if num_peac == 0 else '\nPeacefuls: ' + str(num_peac)
        main_title += ', Atck-speed: 0.5, Leaders-percent: 0.2'
    elif 'leaders' in dic['name']:
        main_title += '\nPeacefuls: 350, Atck-speed: 0.5'
        main_title += ', Leaders-percent: From 0 to 1' if criteria[1] == -1 else ', Leaders-percent: ' + str(criteria[1])
    else:
        main_title += '\nPeacefuls: 350, '
        main_title += 'Atck-speed: From 0.6 to 1.5' if criteria[1] == -1 else 'Atck-speed: ' + str(criteria[1])
        main_title += ', Leaders-percent: 0.2'
    main_title += ', Shooting' if shoot == True else ', Melee'
    
    titles = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    h1 = (list_by(dic, num_peac, 'killed'  , with_app, shoot, normalized, criteria ))
    h2 = (list_by(dic, num_peac, 'rescued' , with_app, shoot, normalized, criteria ))
    h3 = (list_by(dic, num_peac, 'accident', with_app, shoot, normalized, criteria ))
    h4 = (list_by(dic, num_peac, 'room'    , with_app, shoot, normalized, criteria ))
    hi = [h1,h2,h3,h4]
    
    fig = plt.figure(figsize=(10,10))
    gs = gridspec.GridSpec(2, 2, figure=fig)

    for i in range(4):
        j = i // 2
        k = i % 2
        
        h = hi[i]
        h.sort()
        h_mean = np.mean(h)
        h_std = np.std(h)
        h_std = h_std if h_std != 0 else 0.0001
        pdf = stats.norm.pdf(h, h_mean, h_std)
        ax1 = fig.add_subplot(gs[j, k])    
        ax1.set_title(titles[i] + ', Mean: ' + str( "{0:.3f}".format(h_mean) ) + ', Std: ' + str( "{0:.3f}".format(h_std))   )
        
        if (h_std>0.0001):
            ax1.plot(h, pdf,'-o', color='blue')
        ax1.hist(h, density=True, color = 'red', alpha=0.3)
        ax1.axes.get_yaxis().set_visible(False)
    
    plt.suptitle(main_title, y=1.05)
    plt.tight_layout()
    
    if save_file:        
        t=str(datetime.datetime.now())[:-7]
        file_type = t + '.' + save_file
        plt.savefig('../img/show_histograms_'+file_type, bbox_inches='tight', pad_inches=0.3)   
    plt.show()





# This function returns a plot where we are comparing the histograms of a given pair of dictionaries (dic1, dic2)
def compare_histograms ( dic1, dic2, num_peac=350, with_app = 'both', shoot=True, normalized=False, save_file=None, criteria=('',-1) ):
  
    main_title = 'dic1: ' + dic1['name'] + ' (Blue)  vs.  dic2: '+ dic2['name'] + '  (Red)\n'
    if 'peacefuls' in dic1['name']:
        main_title += 'Peacefuls: From 150 to 600' if num_peac == 0 else 'Peacefuls: ' + str(num_peac)
        main_title += ', Atck-speed: 0.5, Leaders-percent: 0.2'
    elif 'leaders' in dic1['name']:
        main_title += 'Peacefuls: 350, Atck-speed: 0.5'
        main_title += ', Leaders-percent: From 0 to 1' if criteria[1] == -1 else ', Leaders-percent: ' + str(criteria[1])
    elif 'rooms' in dic1['name']:
        main_title += 'Peacefuls: 350, Atck-speed: 0.8, Leaders-percent: 0.2'
    else:
        main_title += 'Peacefuls: 350, '
        main_title += 'Atck-speed: From 0.6 to 1.5' if criteria[1] == -1 else 'Atck-speed: ' + str(criteria[1])
        main_title += ', Leaders-percent: 0.2'
    main_title += ', Shooting' if shoot == True else ', Melee\n'
    
    h1  = (list_by(dic1, num_peac, 'killed'  , with_app, shoot, normalized, criteria ))
    h2  = (list_by(dic1, num_peac, 'rescued' , with_app, shoot, normalized, criteria ))
    h3  = (list_by(dic1, num_peac, 'accident', with_app, shoot, normalized, criteria ))
    h4  = (list_by(dic1, num_peac, 'room'    , with_app, shoot, normalized, criteria ))
    
    h1n = (list_by(dic2, num_peac, 'killed'  , with_app, shoot, normalized, criteria ))
    h2n = (list_by(dic2, num_peac, 'rescued' , with_app, shoot, normalized, criteria))
    h3n = (list_by(dic2, num_peac, 'accident', with_app, shoot, normalized, criteria ))
    h4n = (list_by(dic2, num_peac, 'room'    , with_app, shoot, normalized, criteria ))
    
    titles = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    hi     = [h1, h2, h3, h4]
    hin    = [h1n, h2n, h3n, h4n]
    
    fig = plt.figure(figsize=(10,10))
    gs = gridspec.GridSpec(2, 2, figure=fig)
    
    for i in range(4):
        j = i // 2
        k = i % 2
        
        h = hi[i]
        h.sort()
        h_mean = np.mean(h)
        h_std = np.std(h)
        h_std = h_std if h_std != 0 else 0.0001
        pdf = stats.norm.pdf(h, h_mean, h_std)    

        hn = hin[i]
        hn.sort()
        hn_mean = np.mean(hn)
        hn_std = np.std(hn)
        hn_std = hn_std if hn_std != 0 else 0.0001
        pdfn = stats.norm.pdf(hn, hn_mean, hn_std)    
        
        ax1 = fig.add_subplot(gs[j, k]) 
        title = titles[i] + '\n dic1 -> Mean: ' + str( "{0:.3f}".format(h_mean) ) + ', Std: ' + str( "{0:.3f}".format(h_std))
        title += '\n dic2 -> Mean: ' + str( "{0:.3f}".format(hn_mean) ) + ', Std: ' + str( "{0:.3f}".format(hn_std))
        
        ax1.set_title( title )
        if (h_std > 0.0001):
            ax1.plot(h, pdf,'-o', color='blue')
            ax1.hist(h, density=True, color = 'blue', alpha=0.3)
        
        if (hn_std > 0.0001):
            ax1.plot(hn, pdfn,'-o', color='red')   
            ax1.hist(hn, density=True, color = 'red', alpha=0.3)            
        
        ax1.grid(color='lightgrey', linestyle='-')
        ax1.axes.get_yaxis().set_visible(False)

    plt.subplots_adjust(left=None, bottom=-0.5, right=None, top=1, wspace=0.5, hspace=0.5)    
    plt.suptitle(main_title, y=1.05)
    plt.tight_layout()
    
    if save_file:        
        t=str(datetime.datetime.now())[:-7]
        file_type = t + '.' + save_file
        plt.savefig('../img/compare_histograms_'+file_type, bbox_inches='tight', pad_inches=0.3)   
    plt.show()  




        
# Given a dictionary and a target secuence, returns the secuences for killed, rescued, in secure room and accidents
def secuences_by (dic, secuence = '', with_app = 'both', shoot=True, normalized=False):
    
    if secuence == '':
        if dic == dic__mod_1__app_1__attackers_speed or dic == dic__mod_1__app_0__attackers_speed:
            secuence = 'attacker_speed'
        elif dic == dic__mod_1__app_1__leaders or dic == dic__mod_1__app_0__leaders:
            secuence = 'leaders_percentage'
        else:
            secuence = 'people'
    
    if secuence == 'people':        
        rang = range(150,601,50) # We are measuring the results based on number of peacefuls present in simulations
        room     = [ [np.mean(list_by(dic, p, 'room',    with_app, shoot, normalized )) for p in rang] 
                    ,[np.std( list_by(dic, p, 'room',    with_app, shoot, normalized )) for p in rang] ]
        killed   = [ [np.mean(list_by(dic, p, 'killed',  with_app, shoot, normalized )) for p in rang] 
                    ,[np.std( list_by(dic, p, 'killed',  with_app, shoot, normalized )) for p in rang] ]
        rescued  = [ [np.mean(list_by(dic, p, 'rescued', with_app, shoot, normalized )) for p in rang] 
                    ,[np.std( list_by(dic, p, 'rescued', with_app, shoot, normalized )) for p in rang] ] 
        accident = [ [np.mean(list_by(dic, p, 'accident',with_app, shoot, normalized )) for p in rang] 
                    ,[np.std( list_by(dic, p, 'accident',with_app, shoot, normalized )) for p in rang] ]        
    else: 
        p = 350 # Default number of peacefuls presents in simulations when we are showing attacker-speed or leaders percentage secuences
        
        if secuence == 'attacker_speed':
            rang = [x/10 for x in range(6,16)]
        elif secuence == 'leaders_percentage':
            rang = [x/10 for x in range(11)]
               
        room     = [ [np.mean(list_by(dic, p, 'room',    with_app, shoot, normalized, (secuence,s) ) ) for s in rang] 
                    ,[np.std( list_by(dic, p, 'room',    with_app, shoot, normalized, (secuence,s) ) ) for s in rang] ]
        killed   = [ [np.mean(list_by(dic, p, 'killed',  with_app, shoot, normalized, (secuence,s) ) ) for s in rang] 
                    ,[np.std( list_by(dic, p, 'killed',  with_app, shoot, normalized, (secuence,s) ) ) for s in rang] ]
        rescued  = [ [np.mean(list_by(dic, p, 'rescued', with_app, shoot, normalized, (secuence,s) ) ) for s in rang] 
                    ,[np.std( list_by(dic, p, 'rescued', with_app, shoot, normalized, (secuence,s) ) ) for s in rang] ] 
        accident = [ [np.mean(list_by(dic, p, 'accident',with_app, shoot, normalized, (secuence,s) ) ) for s in rang] 
                    ,[np.std( list_by(dic, p, 'accident',with_app, shoot, normalized, (secuence,s) ) ) for s in rang] ]
         
    xaxis = np.array(rang)    
    return [killed,rescued,accident,room, xaxis]




    

# Given a dictionary and a target secuence, this function plots the secuences for killed,rescued,in secure rooms and accidents
# save_file options: 'pdf' , 'png', None
def show_secuences(dic, secuence = '', with_app = 'both', shoot=True, normalized=False, save_file=None):
    
    if secuence == '':
        if dic == dic__mod_1__app_1__attackers_speed or dic == dic__mod_1__app_0__attackers_speed:
            secuence = 'attacker_speed'
        elif dic == dic__mod_1__app_1__leaders or dic == dic__mod_1__app_0__leaders:
            secuence = 'leaders_percentage'
        else:
            secuence = 'people'
            
    main_title =  dic['name']+'\n' 
    main_title += 'Peacefuls: From 150 to 600' if secuence == 'people' else 'Attacker speed: From 0.6 to 1.5' if secuence == 'attacker_speed' else 'Leaders percentage: from 0 to 1'
    main_title += ', Shooting' if shoot == True else ', Melee'
      
    fig = plt.figure(figsize=(10, 10))
    fig.suptitle(main_title)
    gs = gridspec.GridSpec(2, 2, figure=fig)
        
    titles = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    hist = secuences_by(dic,secuence, with_app, shoot, normalized)
    
    l={"linestyle":"--", "linewidth":2, "markeredgewidth":2, "elinewidth":2, "capsize":3}

    xaxis = hist[-1]

    for i in range(4):
        j = i // 2
        k = i % 2
        
        h = hist[i]        

        ax1 = fig.add_subplot(gs[j, k])        
        ax1.set_title( titles[i] )    
        ax1.errorbar(xaxis, h[0], yerr=h[1], **l)
        ax1.grid(color='lightgrey', linestyle='-')
    
    if save_file:        
        t=str(datetime.datetime.now())[:-7]
        file_type = t + '.' + save_file
        plt.savefig('../img/show_secuences_'+file_type, bbox_inches='tight', pad_inches=0.3)   
    plt.show()
    
    
    

# Given two dictionaries and a target secuence, This function plot the secuences comparation for killed, rescued,accidents and in secure rooms
# Admited secuence values: 'people', 'attacker_speed', 'leaders_percentage' 
def compare_secuences ( dic1, dic2, secuence='', with_app = 'both', shoot=True, normalized=False, save_file=None):
              
    if secuence == '':
        if dic1 == dic__mod_1__app_1__attackers_speed or dic1 == dic__mod_1__app_0__attackers_speed:
            secuence = 'attacker_speed'
        elif dic1 == dic__mod_1__app_1__leaders or dic1 == dic__mod_1__app_0__leaders:
            secuence = 'leaders_percentage'
        else:
            secuence = 'people'
            
    main_title = dic1['name']+' (Blue) vs. '+dic2['name']+ ' (Red)\n' 
    main_title += 'Shooting, ' if shoot == True else 'Melee, '
    main_title += 'Peacefuls: From 150 to 600, Attacker speed: 0.5, Leaders percentage: 0.2' if secuence == 'people' else 'Peacefuls: 350, Attacker speed: From 0.6 to 1.5, Leaders percentage: 0.2' if secuence == 'attacker_speed' else 'Peacefuls: 350, Attacker speed: 0.5, Leaders percentage: from 0 to 1'
         
    fig = plt.figure(figsize=(10, 10))
    fig.suptitle(main_title)
    gs = gridspec.GridSpec(2, 2, figure=fig)
        
    titles     = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    hi_app     = secuences_by(dic1,secuence, with_app, shoot, normalized)
    hi_not_app = secuences_by(dic2,secuence, with_app, shoot, normalized)    
    xaxis      = hi_app[-1]

    l_app      = {"linestyle":"--", "linewidth":2, "markeredgewidth":2, "elinewidth":2, "capsize":3, "color":"blue"}
    l_not_app  = {"linestyle":"--", "linewidth":2, "markeredgewidth":2, "elinewidth":2, "capsize":3, "color":"red"}

    for i in range(4):
        j = i // 2
        k = i % 2
        
        h1 = hi_app[i]        
        h_app = np.array(h1)
        h_app[h_app == 0] = np.nan
        
        h2 = hi_not_app[i]        
        h_not_app = np.array(h2)
        h_not_app[h_not_app == 0] = np.nan
        h_not_app = hi_not_app[i] 

        ax1 = fig.add_subplot(gs[j, k])        
        ax1.set_title( titles[i] )    
        ax1.errorbar(xaxis, h_app[0], yerr=h_app[1], **l_app)
        ax1.errorbar(xaxis, h_not_app[0], yerr=h_not_app[1], **l_not_app)
        ax1.grid(color='lightgrey', linestyle='-')
        
    if save_file:
        t=str(datetime.datetime.now())[:-7]
        file_type = t + '.' + save_file
        plt.savefig('../img/compare_secuences_'+file_type , bbox_inches='tight', pad_inches=0.3)     
    plt.show()





read_file(file0)
read_file(file1)
read_file(file2)
read_file(file3)
read_file(file4)
read_file(file5)


# compare_histograms(dic__mod_0__app_1__rooms_0, dic__mod_0__app_0__rooms_0, save_file='pdf')

# compare_histograms(dic__mod_0__app_1__rooms_1, dic__mod_0__app_0__rooms_1, save_file='pdf')

# compare_histograms(dic__mod_1__app_1__rooms_0, dic__mod_1__app_0__rooms_0, save_file='pdf')
# compare_histograms(dic__mod_1__app_1__rooms_1, dic__mod_1__app_0__rooms_1, save_file='pdf')
compare_histograms(dic__mod_0__app_1__rooms_1, dic__mod_0__app_1__rooms_0, save_file='pdf')






