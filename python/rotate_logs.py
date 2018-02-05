#!/usr/bin/env python
# -*- coding:utf8 -*-

# --author:may--
# --time:20170413--
# --modify time:20171010--

import os,string,re,time

MONTH_DEADLINE = [31,28,31,30,31,30,31,31,30,31,30,31]

ROTATE_DAYS = 7
ROTATE_DIR = '/data/log/mobilegame'

def rotate_logs():
    current_date = get_current_date()
    current_month = current_date[-4:-2]
    current_year = current_date[:4]
    if int(current_year) % 4 == 0 and int(current_year) % 100 != 0 or int(current_year) % 400 == 0:
        MONTH_DEADLINE[1] = 29
    for root, dirs, files in os.walk(ROTATE_DIR):
        for filename in files:
            fullpath_file = root + '/' + filename
            if string.split(fullpath_file, '.')[-1] == 'log':
                file_date = ''
                if filename[:4] == 'game':
                    restr = re.compile('\d{4,}')
                    file_date = re.search(restr, fullpath_file).group()
                    file_prefix = 'game'
                elif filename[:4] == 'nlog':
                    file_date = string.split(''.join(string.split(filename, '-')[2:5]), '.')[0]
                    file_prefix = 'nlog'
                elif filename[:5] == 'lobby':
                    restr = re.compile('\d{4,}')
                    file_date = re.search(restr, fullpath_file).group()
                    file_prefix = 'lobby'
                elif filename[:8] == 'platform':
                    restr = re.compile('\d{4,}')
                    file_date = re.search(restr, fullpath_file).group()
                    file_prefix = 'platform'
                if file_date:
                    if int(current_date[-4:-2]) - int(file_date[-4:-2]) == 1:
                        if MONTH_DEADLINE[int(file_date[-4:-2]) - 1] - int(file_date[-2:]) + int(current_date[-2:]) > ROTATE_DAYS:
                            newest_file = get_dir_newest_file(fullpath_file, file_prefix)
                            if check_dir_newest_file_only(fullpath_file, newest_file) == True and os.path.getsize(newest_file) >= 524288000:
                                cmd = 'echo "" > ' + newest_file
                                os.system(cmd)
                            if newest_file != fullpath_file:
                                print(fullpath_file)
                                os.remove(fullpath_file)
                    else:
                        if int(current_date) - int(file_date) > ROTATE_DAYS:
                            newest_file = get_dir_newest_file(fullpath_file, file_prefix)
                            if check_dir_newest_file_only(fullpath_file, newest_file) == True and os.path.getsize(newest_file) >= 524288000:
                                cmd = 'echo "" > ' + newest_file
                                os.system(cmd)
                            if newest_file != fullpath_file:
                                print(fullpath_file)
                                os.remove(fullpath_file)
            elif string.split(fullpath_file, '.')[-1] == 'txt':
                if '-' in filename:
                    file_date = string.split(''.join(string.split(filename, '-')[0:]), '.')[0]
                    file_suffix = '.txt'
                else:
                    file_date = string.split(filename, '.')[-2]
                    file_suffix = '.txt'
                if file_date:
                    if int(current_date[-4:-2]) - int(file_date[-4:-2]) == 1:
                        if MONTH_DEADLINE[int(file_date[-4:-2]) - 1] - int(file_date[-2:]) + int(current_date[-2:]) > ROTATE_DAYS:
                            newest_file = get_dir_newest_file(fullpath_file, file_suffix)
                            if check_dir_newest_file_only(fullpath_file, newest_file) == True and os.path.getsize(newest_file) >= 524288000:
                                cmd = 'echo "" > ' + newest_file
                                os.system(cmd)
                            if newest_file != fullpath_file:
                                print(fullpath_file)
                                os.remove(fullpath_file)
                    else:
                        if int(current_date) - int(file_date) > ROTATE_DAYS:
                            newest_file = get_dir_newest_file(fullpath_file, file_suffix)
                            if check_dir_newest_file_only(fullpath_file, newest_file) == True and os.path.getsize(newest_file) >= 524288000:
                                cmd = 'echo "" > ' + newest_file
                                os.system(cmd)
                            if newest_file != fullpath_file:
                                print(fullpath_file)
                                os.remove(fullpath_file)

def get_current_date():
    return time.strftime("%Y%m%d", time.localtime())

def get_dir_newest_file(fullpath_filename, match_str):
    newest_file_time = 0
    path = os.path.dirname(fullpath_filename) + '/'
    for filename in os.listdir(os.path.dirname(fullpath_filename)):
        if match_str in filename:
            file_ctime = os.stat(path + filename).st_ctime
            if newest_file_time < file_ctime:
                newest_file_time = file_ctime
                newest_file = path + filename
    return newest_file

def check_dir_newest_file_only(fullpath_filename, newest_file):
    count = 0
    newest_file_prefix = '_'.join(newest_file.split('/')[-1].split('_')[0:2])
    path = os.path.dirname(fullpath_filename) + '/'
    for filename in os.listdir(os.path.dirname(fullpath_filename)):
        if os.path.isfile(filename) == True:
            if newest_file_prefix in filename:
                count = count + 1
            if count >= 2:
                return False
    return True

if __name__ == '__main__':
    rotate_logs()
