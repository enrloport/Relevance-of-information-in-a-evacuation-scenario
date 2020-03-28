#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Mar  5 18:31:57 2020

@author: one
"""

import csv
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import numpy as np
import scipy.stats as stats


file0 = "evacuation_scenario:app-T-F,shooting-T-F,peace-150-600,visib-0,sound-0,table-2020-03-06.csv"
file1 = "evacuation_scenario:app-T-F,shooting-T-F,peace-150-600,visib-1,sound-1,table-2020-03-06.csv"

file2 = "evacuation_scenario app-T-F,attacker-speed-0.6-1.5,shooting-T,peace-350,mods-1-table.csv"

dic_app_mod_0 = {}
dic_not_app_mod_0 = {}
dic_app_mod_1 = {}
dic_not_app_mod_1 = {}


class simulation:

    def __init__ (self, shooting, num_p, v_mod, s_mod, ticks, na_k,a_k,t_k, na_a,a_a,t_a, na_r,a_r,t_r, na_i,a_i,t_i):
       
        if shooting == 'true':
            self.shooting = True
        elif shooting == 'false':
            self.shooting = False
        else:
            self.shooting = 0
            
        self.peacefuls = int(num_p)
        self.visib_mod = float(v_mod)
        self.sound_mod = float(s_mod)
        self.ticks = int(ticks)
        
        self.not_app_killed = int(na_k)
        self.app_killed = int(a_k)
        # self.total_killed = int(t_k)
        self.total_killed = self.not_app_killed + self.app_killed
        
        self.not_app_accident = int(na_a)
        self.app_accident = int(a_a)
        self.total_accident = int(t_a)
        
        self.not_app_room = int(na_i)
        self.app_room = int(a_i)
        self.total_room = int(t_i)
        
        self.not_app_rescued = int(na_r)
        self.app_rescued = int(a_r)
        self.total_rescued = int(t_r)
    
    def __str__(self):
        res = "Shooting: " + str(self.shooting) + "\n" + "Peacefuls: " + str(self.peacefuls) + "\n" + "Ticks: " + str(self.ticks) + "\n" + "App killed: " + str(self.app_killed) + "\n" + "Not App killed: " + str(self.not_app_killed) + "\n" + "Total killed: " + str(self.total_killed) + "\n" + "App rescued: " + str(self.app_rescued) + "\n" + "Not App rescued: " + str(self.not_app_rescued) + "\n" + "Total rescued: " + str(self.total_rescued) + "\n" + "App accident: " + str(self.app_accident) + "\n" + "Not App accident: " + str(self.not_app_accident) + "\n" + "Total accident: " + str(self.total_accident) + "\n" + "App secure room: " + str(self.app_room) + "\n" + "Not App secure room: " + str(self.not_app_room) + "\n" + "Total secure room: " + str(self.total_room) + "\n"
        return res
    
    def count_not_app(self):
        return self.not_app_killed + self.not_app_accident + self.not_app_room + self.not_app_rescued
    
    def count_app(self):
        return self.app_killed + self.app_accident + self.app_room + self.app_rescued
                

def read_files(file0, file1):
    with open(file0, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            try:
                # print(row[0])
                if row[1]== 'true':
                    dic_app_mod_0[int(row[0])] = (simulation( row[2], row[3], row[4], row[5]
                                        , row[23], row[24], row[25], row[26], row[27], row[28], row[29], row[30], row[31], row[32], row[33], row[34], row[35]  )  )
                else:
                    dic_not_app_mod_0[int(row[0])] = (simulation( row[2], row[3], row[4], row[5]
                                        , row[23], row[24], row[25], row[26], row[27], row[28], row[29], row[30], row[31], row[32], row[33], row[34], row[35]  )  )
            except:
                pass      
    
    with open(file1, 'r') as f:
        reader = csv.reader(f)
        for row in reader:
            try:
                # print(row[0])
                if row[1]== 'true':
                    dic_app_mod_1[int(row[0])] = (simulation( row[2], row[3], row[4], row[5]
                                        , row[23], row[24], row[25], row[26], row[27], row[28], row[29], row[30], row[31], row[32], row[33], row[34], row[35]  )  )
                else:
                    dic_not_app_mod_1[int(row[0])] = (simulation( row[2], row[3], row[4], row[5]
                                        , row[23], row[24], row[25], row[26], row[27], row[28], row[29], row[30], row[31], row[32], row[33], row[34], row[35]  )  )
            except:
                pass


#  Options: 'rescued', 'killed', 'room', 'accident'
def list_by (dic, num_peac, result='rescued', targets = 'both', shoot=True, normalized=True ):
    res = []  
    
    keys = sorted(dic.keys()) 
    
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
    
    if num_peac == 0:
        for k in keys:
            if dic[k].shooting == shoot:
                norm = dic[k].peacefuls if normalized else 1
                res.append(select(dic[k])[2] / norm )            
    elif targets == 'app':
        for k in keys:
            if dic[k].shooting == shoot and dic[k].peacefuls == num_peac:
                norm = dic[k].count_app if normalized else 1                    
                res.append(select(dic[k])[0] / norm )            
    elif targets == 'not_app':
        for k in keys:
            if dic[k].shooting == shoot and dic[k].peacefuls == num_peac:
                norm = dic[k].count_app if normalized else 1
                res.append(select(dic[k])[1] / norm ) 
    else:
        for k in keys:
            if dic[k].shooting == shoot and dic[k].peacefuls == num_peac:
                norm = dic[k].peacefuls if normalized else 1
                res.append(select(dic[k])[2] / norm ) 
    return res


def show_histograms (dic, num_peac=0, with_app = 'both', shoot=True, normalized=False):
    main_title = 'App: activated' if dic == dic_app_mod_1 or dic == dic_app_mod_0 else 'App: deactivated'
    main_title += ', Visibility and sound mod: 1 \n' if dic == dic_app_mod_1 or dic == dic_not_app_mod_1 else ', Visibility and sound mod: 0 \n' 
    main_title += 'Peacefuls: From 150 to 600' if num_peac == 0 else 'Peacefuls: ' + str(num_peac)
    main_title += ', Shooting' if shoot == True else ', Melee'
    
    titles = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    h1 = (list_by(dic, num_peac, 'killed'  , with_app, shoot, normalized ))
    h2 = (list_by(dic, num_peac, 'rescued' , with_app, shoot, normalized ))
    h3 = (list_by(dic, num_peac, 'accident', with_app, shoot, normalized ))
    h4 = (list_by(dic, num_peac, 'room'    , with_app, shoot, normalized ))
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
        pdf = stats.norm.pdf(h, h_mean, h_std)
        ax1 = fig.add_subplot(gs[j, k])    
        ax1.set_title(titles[i] + ', Mean: ' + str( "{0:.3f}".format(h_mean) ) + ', Std: ' + str( "{0:.3f}".format(h_std))   ) 
        ax1.plot(h, pdf, '-o')
        ax1.hist(h, density=True, color = 'red', alpha=0.3)
    
    plt.suptitle(main_title, y=1.05)
    plt.tight_layout()
    plt.show()


def compare_with_and_without_info (num_peac=150, mod=1, with_app = 'both', shoot=True, normalized=False):
      
    if mod == 1:
        dic1=dic_app_mod_1
        dic2=dic_not_app_mod_1
    else:
        dic1=dic_app_mod_0
        dic2=dic_not_app_mod_0
        
    main_title = 'Visibility and sound mod: 1 \n' if dic1 == dic_app_mod_1 else 'Visibility and sound mod: 0 \n' 
    main_title += 'Peacefuls: From 150 to 600' if num_peac == 0 else 'Peacefuls: ' + str(num_peac)
    main_title += ', Shooting' if shoot == True else ', Melee'
    
    h1  = (list_by(dic1, num_peac, 'killed'  , with_app, shoot, normalized ))
    h2  = (list_by(dic1, num_peac, 'rescued' , with_app, shoot, normalized ))
    h3  = (list_by(dic1, num_peac, 'accident', with_app, shoot, normalized ))
    h4  = (list_by(dic1, num_peac, 'room'    , with_app, shoot, normalized ))
    
    h1n = (list_by(dic2, num_peac, 'killed'  , with_app, shoot, normalized ))
    h2n = (list_by(dic2, num_peac, 'rescued' , with_app, shoot, normalized ))
    h3n = (list_by(dic2, num_peac, 'accident', with_app, shoot, normalized ))
    h4n = (list_by(dic2, num_peac, 'room'    , with_app, shoot, normalized ))
    
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
        pdf = stats.norm.pdf(h, h_mean, h_std)    

        hn = hin[i]
        hn.sort()
        hn_mean = np.mean(hn)
        hn_std = np.std(hn)
        pdfn = stats.norm.pdf(hn, hn_mean, hn_std)    

        ax1 = fig.add_subplot(gs[j, k]) 
        title = titles[i] + '\n App-ON -> Mean: ' + str( "{0:.3f}".format(h_mean) ) + ', Std: ' + str( "{0:.3f}".format(h_std))
        title += '\n App-OFF -> Mean: ' + str( "{0:.3f}".format(hn_mean) ) + ', Std: ' + str( "{0:.3f}".format(hn_std))
        
        ax1.set_title( title ) 
        ax1.plot(h, pdf,'-o', color='blue')
        ax1.hist(h, density=True, color = 'blue', alpha=0.3)
        ax1.plot(hn, pdfn,'-o', color='red')
        ax1.hist(hn, density=True, color = 'red', alpha=0.3)
        ax1.grid(color='lightgrey', linestyle='-')

    plt.suptitle(main_title, y=1.05)
    plt.tight_layout()
    plt.show()  
    
    
def secuences (dic, with_app = 'both', shoot=True, normalized=False):
    main_title =  'App: activated' if dic == dic_app_mod_1 or dic == dic_app_mod_0 else 'App: deactivated'
    main_title += ', Visibility and sound mod: 1 \n' if dic == dic_app_mod_1 or dic == dic_not_app_mod_1 else ', Visibility and sound mod: 0 \n' 
    main_title += 'Peacefuls: From 150 to 600'
    main_title += ', Shooting' if shoot == True else ', Melee'
      
    xaxis = np.array([150,200,250,300,350,400,450,500,550,600])
    rang = range(150,601,50)
    
    room     = [ [np.mean(list_by(dic, p, 'room',    with_app, shoot, normalized )) for p in rang] 
                ,[np.std( list_by(dic, p, 'room',    with_app, shoot, normalized )) for p in rang] ]
    killed   = [ [np.mean(list_by(dic, p, 'killed',  with_app, shoot, normalized )) for p in rang] 
                ,[np.std( list_by(dic, p, 'killed',  with_app, shoot, normalized )) for p in rang] ]
    rescued  = [ [np.mean(list_by(dic, p, 'rescued', with_app, shoot, normalized )) for p in rang] 
                ,[np.std( list_by(dic, p, 'rescued', with_app, shoot, normalized )) for p in rang] ] 
    accident = [ [np.mean(list_by(dic, p, 'accident',with_app, shoot, normalized )) for p in rang] 
                ,[np.std( list_by(dic, p, 'accident',with_app, shoot, normalized )) for p in rang] ]

    fig = plt.figure(figsize=(10, 10))
    fig.suptitle(main_title)
    gs = gridspec.GridSpec(2, 2, figure=fig)
        
    titles = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    hi = [killed,rescued,accident,room]
    
    l={"linestyle":"--", "linewidth":2, "markeredgewidth":2, "elinewidth":2, "capsize":3}


    for i in range(4):
        j = i // 2
        k = i % 2
        
        h = hi[i]        

        ax1 = fig.add_subplot(gs[j, k])        
        ax1.set_title( titles[i] )    
        ax1.errorbar(xaxis, h[0], yerr=h[1], **l)
        ax1.grid(color='lightgrey', linestyle='-')
     
    plt.show()
    
    
def compare_secuences ( mod=0, with_app = 'both', shoot=True, normalized=False):
      
    if mod == 1:
        dic1=dic_app_mod_1
        dic2=dic_not_app_mod_1
    else:
        dic1=dic_app_mod_0
        dic2=dic_not_app_mod_0
        
    main_title = 'Visibility and sound mod: 1 \n' if dic1 == dic_app_mod_1 else 'Visibility and sound mod: 0 \n' 
    main_title += 'Peacefuls: From 150 to 600' 
    main_title += ', Shooting' if shoot == True else ', Melee'
      
    xaxis = np.array([150,200,250,300,350,400,450,500,550,600])
    
    room_app     = [ [np.mean(list_by(dic1, p, 'room',    with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic1, p, 'room',    with_app, shoot, normalized )) for p in range(150,601,50)] ]
    killed_app   = [ [np.mean(list_by(dic1, p, 'killed',  with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic1, p, 'killed',  with_app, shoot, normalized )) for p in range(150,601,50)] ]
    rescued_app  = [ [np.mean(list_by(dic1, p, 'rescued', with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic1, p, 'rescued', with_app, shoot, normalized )) for p in range(150,601,50)] ] 
    accident_app = [ [np.mean(list_by(dic1, p, 'accident',with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic1, p, 'accident',with_app, shoot, normalized )) for p in range(150,601,50)] ]
     
    room_not_app     = [ [np.mean(list_by(dic2, p, 'room',    with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic2, p, 'room',    with_app, shoot, normalized )) for p in range(150,601,50)] ]
    killed_not_app   = [ [np.mean(list_by(dic2, p, 'killed',  with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic2, p, 'killed',  with_app, shoot, normalized )) for p in range(150,601,50)] ]
    rescued_not_app  = [ [np.mean(list_by(dic2, p, 'rescued', with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic2, p, 'rescued', with_app, shoot, normalized )) for p in range(150,601,50)] ] 
    accident_not_app = [ [np.mean(list_by(dic2, p, 'accident',with_app, shoot, normalized )) for p in range(150,601,50)] 
                ,[np.std( list_by(dic2, p, 'accident',with_app, shoot, normalized )) for p in range(150,601,50)] ]

    fig = plt.figure(figsize=(10, 10))
    fig.suptitle(main_title)
    gs = gridspec.GridSpec(2, 2, figure=fig)
        
    titles = ['KILLED', 'RESCUED', 'ACCIDENT', 'SECURE ROOM']
    hi_app = [killed_app,rescued_app,accident_app,room_app]
    hi_not_app = [killed_not_app,rescued_not_app,accident_not_app,room_not_app]
    

    l_app ={"linestyle":"--", "linewidth":2, "markeredgewidth":2, "elinewidth":2, "capsize":3}
    l_not_app ={"color":"red", "linestyle":"--", "linewidth":2, "markeredgewidth":2, "elinewidth":2, "capsize":3}

    for i in range(4):
        j = i // 2
        k = i % 2
        
        h1 = hi_app[i]        
        h_app = np.array(h1)
        h_app[h_app == 0] = np.nan
        # h_app = hi_app[i]
        
        h2 = hi_not_app[i]        
        h_not_app = np.array(h2)
        h_not_app[h_not_app == 0] = np.nan
        h_not_app = hi_not_app[i] 
        # h_not_app = hi_not_app[i]        

        ax1 = fig.add_subplot(gs[j, k])        
        ax1.set_title( titles[i] )    
        ax1.errorbar(xaxis, h_app[0], yerr=h_app[1], **l_app)
        ax1.errorbar(xaxis, h_not_app[0], yerr=h_not_app[1], **l_not_app)
        ax1.grid(color='lightgrey', linestyle='-')
     
    plt.show()
    

def histogram (dic=dic_app_mod_1, num_peac=0, result='rescued', with_app = 'both', shoot=True, normalized=False):
    main_title = 'App: activated' if dic == dic_app_mod_1 or dic == dic_app_mod_0 else 'App: deactivated'
    main_title += ', Visibility and sound mod: ' + '1 \n' if dic == dic_app_mod_1 or dic == dic_app_mod_1 else '0 \n' 
    main_title += ', Peacefuls: From 150 to 600' if num_peac == 0 else ', Peacefuls: ' + str(num_peac)
    main_title += ', Shooting' if shoot == True else ', Melee'
    
    h = list_by(dic, num_peac, result, with_app, shoot, normalized )
    h.sort()
    hmean = np.mean(h)
    hstd = np.std(h)
    pdf = stats.norm.pdf(h, hmean, hstd)
    plt.suptitle(main_title, y = 1.03)
    plt.title(result + ' - Mean: ' + str( "{0:.3f}".format(hmean) ) + ', Std: ' + str( "{0:.3f}".format(hstd) ) )
    plt.plot(h, pdf, '-o')
    plt.hist(h, density=True)
    plt.show()


read_files(file0, file1)









