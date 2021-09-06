# -*- coding: utf-8 -*-
# !/usr/bin/python3
# 20.05.10 by suke

"""
建议在该文件路径下运行开启指令(screen -L -Logfile foralive.log -dmS foralive python3 foralive.py)，关闭指令(screen -X -S foralive quit)
默认路径在getpath函数中，如需修改，请使用绝对路径按照下行格式修改开启命令。(路径结尾不要带斜杠
screen -L -Logfile foralive.log -dmS foralive python3 foralive.py 存档路径
需要关闭某功能请查看最底

1.闲置超过设定时间后重置
2.天数超过设定天数后转无尽
3.半小时检测一次更新
4.8分钟备份一次聊天记录

    待做     30天前12小时，30天后24小时  无人重置  # 有点麻烦，先推迟
            监测cpu负载，高负载过久重启  # 条件很难判定，有好的想法再说
            自动更新mod  # steamcmd貌似在做，等有mod更新试验一下再看


"""
from json import loads
from os import listdir, mkdir, remove, rename, stat, walk
from os.path import abspath, dirname, exists, expanduser, isdir, join as pathjoin, normpath
from re import compile as recompile, findall
from shutil import copyfile
from subprocess import Popen, PIPE
from sys import argv
from threading import Timer
from time import localtime, sleep, strftime, time
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def activity_time(path_cluster_):
    # 获取游戏目录下，所有玩家meta快照文件的最后修改时间。利用玩家快照文件进行判断，不受服务器重启影响。
    try:
        mtimes = []
        for rt, dirs, files in walk(path_cluster_):
            for i in files:
                if len(rt.split('/')[-1]) == 12:
                    if '.meta' in i:
                        file_path = pathjoin(rt, i)
                        file_mtime = stat(abspath(file_path)).st_mtime
                        mtimes.append(file_mtime)
        if mtimes:
            mtimes.sort(reverse=True)
            return mtimes[0]
        else:
            return 0
    except Exception as e:
        print(' ' * 19, 'activity_time函数出错')
        print(' ' * 19, e)


def survival_days(path_cluster_):
    try:
        for_path = []
        for rt, dirs, files in walk(path_cluster_):  # 获取最新存档快照的路径
            for i in files:
                if len(rt.split('/')[-1]) == 16:
                    if '.meta' in i:
                        file_path = pathjoin(rt, i)
                        file_mtime = stat(abspath(file_path)).st_mtime
                        for_path.append((file_path, file_mtime))
        if not for_path:
            days, last_time = 0, 0
        else:
            for_path.sort(key=lambda x: x[1], reverse=True)
            last_time = for_path[0][1]
            with open(for_path[0][0], 'r', encoding='utf-8') as f:
                data = f.read()
            data = data.split(',')
            days = 0
            for i in data:
                if 'cycles' in i:
                    pattern = recompile(r'\d+')
                    days = pattern.findall(i)[0]
        return int(days), float(last_time)
    except Exception as e:
        print(' ' * 19, 'survival_days函数出错')
        print(' ' * 19, e)
        return 0, 0


def reset(path_cluster_, path_dst_, time_to_reset_=24):  # (存档位置， 服务器程序位置， 超时重置时间(单位/hour))
    t = 3600
    try:
        print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '检测是否需要重置')
        cluster = pathjoin(path_cluster_, 'cluster.ini')

        # 获取最后活动时间
        activity_time_ = activity_time(path_cluster_)
        if not activity_time_:
            print(' ' * 20 + '未找到玩家快照文件')
            print(' ' * 20 + '不需要重置')
            t = time_to_reset_ * 60 * 60 + 30
            return
        ttime = strftime("%Y.%m.%d %H:%M:%S", localtime(activity_time_))
        print(' ' * 20 + '最后活动时间：' + ttime)

        if time() - activity_time_ < time_to_reset_ * 60 * 60:  # 超过24小时无人上线，重置世界
            print(' ' * 20 + '不需要重置')
            t = activity_time_ + (time_to_reset_ * 60 * 60 + 30) - time()
            return
        # 修改设置，改为生存模式
        with open(cluster, 'r', encoding='utf-8') as f, open(cluster + '.temp', 'w+', encoding='utf-8') as f2:
            data = f.readlines()
            newdata = []
            for i in data:
                if 'game_mode' in i:
                    i = i.replace('endless', 'survival')
                newdata.append(i)
            newdata = ''.join(newdata)
            f2.write(newdata)
        remove(cluster)
        rename(cluster + '.temp', cluster)

        print(' ' * 20 + '开始重置世界')
        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        start = Popen('screen -ls', shell=True, stdout=PIPE, stderr=PIPE, encoding='utf-8')  # 检查是否有世界开启，没有则最后不开启世界
        stout, sterr = start.communicate()
        if 'DST_' in stout:
            start = 'true'
        else:
            start = ''

        Popen('screen -x -S ' + screen_name_master + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                     '', shell=True).wait(1)  # 关闭地上
        Popen('screen -x -S ' + screen_name_cave + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                   '', shell=True).wait(1)  # 关闭地下
        sleep(10)
        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        if start:
            dir_cluster = path_cluster_.split('/')[-1]
            Popen('screen -dmS ' + screen_name_master +
                  ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
                  ' -shard Master', shell=True, cwd=path_dst_).wait(1)  # 开启地上
            Popen('screen -dmS ' + screen_name_cave +
                  ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
                  ' -shard Caves', shell=True, cwd=path_dst_).wait(1)  # 开启地下
        sleep(90)
        Popen('screen -x -S ' + screen_name_master + ' -p 0 -X stuff "c_regenerateworld()\n"'
                                                     '', shell=True).wait(1)  # 重置世界
        t = time_to_reset_ * 60 * 60 + 30
    except Exception as e:
        print(' ' * 19, 'reset函数出错')
        print(' ' * 19, e)
    finally:
        print(' ' * 20 + '下次检测时间：%s' % strftime("%Y.%m.%d %H:%M:%S", localtime(time() + t)))
        Timer(t, reset, [path_cluster_, path_dst_, time_to_reset_]).start()  # 间隔t秒后再次执行该函数


def for_endless(path_cluster_, path_dst_, day_to_change_=40, time_to_reset_=24):  # (存档位置， 服务器程序位置， 间隔检测时间，单位/s)
    t = 480
    try:
        print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '检测是否转为无尽')
        cluster = pathjoin(path_cluster_, 'cluster.ini')
        with open(cluster, 'r', encoding='utf-8') as f:
            data = f.readlines()
        for i in data:
            if 'game_mode' in i:
                if 'survival' not in i and 'endless' in i:
                    print(' ' * 20 + '已经是无尽')
                    activity_time_ = activity_time(path_cluster_)
                    if activity_time_:
                        if activity_time_ - time() + time_to_reset_ * 60 * 60 <= 0:
                            t = 60
                        else:
                            t = day_to_change_ * 8 * 60 + activity_time_ - time() + time_to_reset_ * 60 * 60
                    else:
                        t = day_to_change_ * 8 * 60
                    return

        days, last_time = survival_days(path_cluster_)
        if days == 0:
            print(' ' * 20 + '未找到世界快照文件')
            print(' ' * 20 + '不转为无尽')
            t = day_to_change_ * 8 * 60
            return

        if days <= (day_to_change_ - 2):
            print(' ' * 20 + '不转为无尽')
            t = (day_to_change_ - 1 - days) * 8 * 60
            return
        if days == (day_to_change_ - 1):
            print(' ' * 20 + '不转为无尽')
            if time() - last_time <= 8 * 60:
                t = 8 * 60 - int(time() - last_time) + 5
            return
        # 修改设置，改为无尽模式
        with open(cluster, 'r', encoding='utf-8') as f, open(cluster + '.temp', 'w+', encoding='utf-8') as f2:
            data = f.readlines()
            newdata = []
            for i in data:
                if 'game_mode' in i:
                    i = i.replace('survival', 'endless')
                newdata.append(i)
            newdata = ''.join(newdata)
            f2.write(newdata)
        remove(cluster)
        rename(cluster + '.temp', cluster)
        print(' ' * 20 + '即将重启为无尽模式')
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'请注意 房间将于120s后*重启*以改为无尽模式\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(90)
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'请注意 房间将于30s后*重启*以改为无尽模式\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(20)
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'房间将于10s后重启，预计60s后可重新连接\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(10)
        Popen('screen -x -S ' + screen_name_master + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                     '', shell=True).wait(1)
        Popen('screen -x -S ' + screen_name_cave + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                   '', shell=True).wait(1)
        sleep(10)
        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        dir_cluster = path_cluster_.split('/')[-1]
        Popen('screen -dmS ' + screen_name_master +
              ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
              ' -shard Master', shell=True, cwd=path_dst_).wait(1)  # 开启地上
        Popen('screen -dmS ' + screen_name_cave +
              ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
              ' -shard Caves', shell=True, cwd=path_dst_).wait(1)  # 开启地下
        print(' ' * 20 + '已更改为无尽模式')
        t = day_to_change_ * 8 * 60
    except Exception as e:
        print(' ' * 19, 'for_endless函数出错')
        print(' ' * 19, e)
        t = 60
    finally:
        print(' ' * 20 + '下次检测时间：%s' % strftime("%Y.%m.%d %H:%M:%S", localtime(time() + t)))
        Timer(t, for_endless, [path_cluster_, path_dst_, day_to_change_, time_to_reset_]).start()  # 间隔t秒后再次执行该函数


def update(path_cluster_, path_dst_, path_steamcmd_, tick=0, tick2=0):
    path_version = pathjoin(dirname(path_dst_), 'version.txt')
    time_start = time()
    tick += 1
    try:
        if tick != 1 and tick != 49:
            pass
        elif tick == 49:
            if not tick2:
                print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '过去一天中检测更新48次，无可用更新')
            else:
                print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '过去一天中检测更新48次，' + '更新' + str(tick2) + '次')
            tick = 1
            tick2 = 0
        elif tick == 1:
            print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '正在检测更新')
        req = Request(url='https://forums.kleientertainment.com/game-updates/dst/')
        response = urlopen(req)
        result = response.read().decode('utf-8')
        response.close()
        pattern = recompile(r'<h3[\W\w]*?</h3>')
        newversion2 = ''.join([i for i in pattern.findall(result) if 'Release' in i])
        pattern2 = recompile('\t[0-9]{6}\n')
        newversion = [i.strip() for i in pattern2.findall(newversion2)]
        newversion.sort(reverse=True)
        if not newversion:
            print(' ' * 20 + '获取版本号失败')
            return
        with open(path_version, 'r', encoding='utf-8') as f:
            data = f.read()
            pattern = recompile('[0-9]{6}')
            version = pattern.search(data).group(0)

        if newversion[0] == version:
            if tick == 1:
                print(' ' * 20 + '无可用更新')
            return
        # 更新游戏
        print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '开始更新游戏')
        tick2 += 1

        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        start = Popen('screen -ls', shell=True, stdout=PIPE, stderr=PIPE, encoding='utf-8')  # 检查是否有世界开启，没有则最后不开启世界
        stout, sterr = start.communicate()
        if 'DST_' in stout:
            start = 'true'
        else:
            start = ''

        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'请注意 房间将于120s后*重启*以更新\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(90)
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'请注意 房间将于30s后*重启*以更新\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(20)
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'房间将于10s后重启更新，预计5分钟内完成\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(10)
        Popen('screen -x -S ' + screen_name_master + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                     '', shell=True).wait(1)  # 关闭地上
        Popen('screen -x -S ' + screen_name_cave + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                   '', shell=True).wait(1)  # 关闭地下
        sleep(10)
        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        times = 0
        path_dst_bin_dir = dirname(path_dst_)
        while 1:
            times += 1
            up = Popen('./steamcmd.sh +login anonymous +force_install_dir ' + path_dst_bin_dir +
                       ' +app_update 343050 validate +quit'
                       '', shell=True, stdout=PIPE, stderr=PIPE, encoding='utf-8', cwd=path_steamcmd_)  # 更新游戏
            out, err = up.communicate()
            if 'Success' in out:
                break
            if times > 5:
                print(' ' * 20 + '多次更新失败')
                break
        sleep(1)
        if start:
            dir_cluster = path_cluster_.split('/')[-1]
            Popen('screen -dmS ' + screen_name_master +
                  ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
                  ' -shard Master', shell=True, cwd=path_dst_).wait(1)  # 开启地上
            Popen('screen -dmS ' + screen_name_cave +
                  ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
                  ' -shard Caves', shell=True, cwd=path_dst_).wait(1)  # 开启地下
        if times <= 5:
            print(' ' * 20 + '更新完毕')
    except Exception as e:
        print(' ' * 19, 'update函数出错')
        print(' ' * 19, e)
    finally:
        t = 1800 - (time() - time_start)
        if t <= 0:
            t = 1800
        Timer(t, update, [path_cluster_, path_dst_, path_steamcmd_, tick, tick2]).start()  # 间隔t秒后再次执行该函数


def chatlog(path_cluster_, time_to_backup=8):
    try:
        path_chatlog = pathjoin(path_cluster_, 'Master/server_chat_log.txt')
        path_chatlog_bakdir = pathjoin(path, 'chatlog')
        time_for_path = strftime("%Y.%m.%d_%H", localtime(time()))
        path_chatlog_bakdir2 = pathjoin(path_chatlog_bakdir, time_for_path[:-3])
        path_chatlog_bakfile = pathjoin(path_chatlog_bakdir2, time_for_path + '.txt')
        if exists(path_chatlog):
            if not exists(path_chatlog_bakdir):
                mkdir(path_chatlog_bakdir)
            if not exists(path_chatlog_bakdir2):
                mkdir(path_chatlog_bakdir2)
            if exists(path_chatlog_bakfile):
                with open(path_chatlog, 'rb') as f:
                    data = f.read(1000)
                with open(path_chatlog_bakfile, 'rb') as f2:
                    data2 = f2.read(1000)
                if data2 in data:
                    copyfile(path_chatlog, path_chatlog_bakfile)
                else:
                    path_chatlog_bakfile2 = pathjoin(path_chatlog_bakdir2, time_for_path + '_2.txt')
                    copyfile(path_chatlog, path_chatlog_bakfile2)
            else:
                copyfile(path_chatlog, path_chatlog_bakfile)
    except Exception as e:
        print(' ' * 19, 'chatlod函数出错')
        print(' ' * 19, e)
    finally:
        Timer(time_to_backup * 60, chatlog, [path_cluster_, time_to_backup]).start()  # 间隔t秒后再次执行该函数


def get_mod_path(path_dst_bin_dir_):
    try:
        mod_path_list = []
        dir_path1 = pathjoin(path_dst_bin_dir_, 'mods')
        dir_path2 = pathjoin(path_dst_bin_dir_, 'ugc_mods/MyDediServer/Master/content/322330')
        dir_path3 = pathjoin(path_dst_bin_dir_, 'ugc_mods/MyDediServer/Caves/content/322330')

        with open(pathjoin(dir_path1, 'dedicated_server_mods_setup.lua'), 'r') as f:
            data = f.read()
        mod_list = findall(r'[\d]+', data)
        for mod_id in mod_list:
            path_tmp1 = pathjoin(pathjoin(dir_path1, 'workshop-' + mod_id), 'modinfo.lua')
            path_tmp2 = pathjoin(pathjoin(dir_path2, mod_id), 'modinfo.lua')
            path_tmp3 = pathjoin(pathjoin(dir_path3, mod_id), 'modinfo.lua')
            if exists(path_tmp2):
                mod_path_list.append(path_tmp2)
            elif exists(path_tmp3):
                mod_path_list.append(path_tmp3)
            elif exists(path_tmp1):
                mod_path_list.append(path_tmp1)
            else:
                print(' ' * 20 + 'mod {} 尚未下载'.format(mod_id))

        return mod_path_list
    except Exception as e:
        print(' ' * 19, 'get_mod_path函数出错')
        print(' ' * 19, e)


def get_mod_version(path_dst_bin_dir_):
    try:
        mod_version = {}
        mod_path_list = get_mod_path(path_dst_bin_dir_)
        for mod_path in mod_path_list:
            mod_id = mod_path.split(normpath('/'))[-2].replace('workshop-', '')
            with open(mod_path, 'rb') as f:
                data = f.read()
            data = data.replace(b'\n', b'').replace(b'\r', b'')
            mod_info = {}

            too_many_blank = findall(b'version[ ]*=', data)
            for blank in too_many_blank:
                data = data.replace(blank, b'version=')
            too_many_blank2 = findall(b'=[ ]*"', data)
            for blank in too_many_blank2:
                data = data.replace(blank, b'="')
            version = str(findall(rb'(?<=version=")[\W\w]*?(?=")', data)[0], encoding='utf-8')
            mod_info['version'] = version

            too_many_blank3 = findall(b'name[ ]*=', data)
            for blank in too_many_blank3:
                data = data.replace(blank, b'name=')
            too_many_blank4 = findall(b'=[ ]*"', data)
            for blank in too_many_blank4:
                data = data.replace(blank, b'="')
            name = findall(rb'(?<=name=\[\[)[\W\w]*?(?=]])', data)
            if not name:
                name = findall(rb'(?<=name=")[\W\w]*?(?=")', data)
            if name:
                mod_info['name'] = str(name[0], encoding='utf-8')

            mod_version[mod_id] = mod_info

        return mod_version
    except Exception as e:
        print(' ' * 19, 'get_mod_version函数出错')
        print(' ' * 19, e)


def getmodinfo(id_='1699194522'):
    try:
        url = 'https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/'
        headers = {
            'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) '
                          'Chrome/89.0.4389.90 Safari/537.36 ',
            "Content-Type": "application/x-www-form-urlencoded"
        }
        data = {
            'itemcount': '1',
            'publishedfileids[0]': id_
        }

        data = urlencode(data).encode('utf-8')
        req = Request(url=url, data=data, headers=headers)
        response = urlopen(req, timeout=20)
        result = response.read().decode('utf-8')
        response.close()

        # 格式化数据，输出id对应的标题和版本
        data = loads(result)
        version = ''
        for tags in data.get('response').get('publishedfiledetails')[0].get("tags"):
            tag_version = tags.get('tag')
            if 'version' in tag_version:
                version = tag_version.replace('version:', '')

        return version
    except Exception as e:
        print(' ' * 19, 'getmodinfo函数出错')
        print(' ' * 19, e)


def update_mod(path_cluster_, path_dst_, tick=0, tick2=0):
    time_start = time()
    tick += 1
    try:
        if tick != 1 and tick != 49:
            pass
        elif tick == 49:
            if not tick2:
                print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '过去一天中检测mod更新48次，无可用更新')
            else:
                print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '过去一天中检测mod更新48次，' + '更新' + str(tick2) + '次')
            tick = 1
            tick2 = 0
        elif tick == 1:
            print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '正在检测mod更新')

        path_dst_bin_dir = dirname(path_dst_)
        local_versions = get_mod_version(path_dst_bin_dir)
        need_update = []
        for i in local_versions:
            remote_version = getmodinfo(i)
            if remote_version.replace(' ', '') == local_versions.get(i).get('version').replace(' ', ''):
                # print('mod {0} 不需要更新'.format(local_versions.get(i).get('name')))
                pass
            else:
                # print('mod {0} 需要更新'.format(local_versions.get(i).get('name')))
                # print(remote_version, local_versions.get(i).get('version'))
                need_update.append(i)
        need_update_name = [local_versions.get(i).get('name') for i in need_update]
        if not need_update:
            if tick == 1:
                print(' ' * 20 + '无可用mod更新')
            return

        mod_name_list = '、'.join([local_versions.get(i).get('name', ' ') for i in local_versions])
        print(strftime("%Y.%m.%d %H:%M:%S", localtime(time())), '开始更新mod ' + mod_name_list)
        tick2 += 1

        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        start = Popen('screen -ls', shell=True, stdout=PIPE, stderr=PIPE, encoding='utf-8')  # 检查是否有世界开启，没有则最后不开启世界
        stout, sterr = start.communicate()
        if 'DST_' in stout:
            start = 'true'
        else:
            start = ''

        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'请注意 房间将于120s后*重启*以更新mod ' + mod_name_list + '\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(90)
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'请注意 房间将于30s后*重启*以更新mod ' + mod_name_list + '\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(20)
        Popen('screen -x -S ' + screen_name_master +
              ' -p 0 -X stuff "c_announce(\'房间将于10s后重启更新mod ' + mod_name_list + '，预计5分钟内完成\')\n" > /dev/null 2>&1'
              '', shell=True).wait(1)
        sleep(10)
        Popen('screen -x -S ' + screen_name_master + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                     '', shell=True).wait(1)  # 关闭地上
        Popen('screen -x -S ' + screen_name_cave + ' -p 0 -X stuff "c_shutdown(true)\n" > /dev/null 2>&1'
                                                   '', shell=True).wait(1)  # 关闭地下
        sleep(10)
        Popen('screen -wipe > /dev/null 2>&1', shell=True).wait(1)  # 清理无效的screen作业
        times = 0
        while 1:
            dir_clu = path_cluster_.split('/')[-1]
            times += 1
            up = Popen('./dontstarve_dedicated_server_nullrenderer -cluster ' + dir_clu + ' -only_update_server_mods'
                       '', shell=True, stdout=PIPE, stderr=PIPE, encoding='utf-8', cwd=path_dst_)  # 更新游戏
            out, err = up.communicate()
            if 'FinishDownloadingServerMods Complete' in out:
                break
            if times > 5:
                print(' ' * 20 + '多次更新mod失败')
                break
        sleep(1)
        if start:
            dir_cluster = path_cluster_.split('/')[-1]
            Popen('screen -dmS ' + screen_name_master +
                  ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
                  ' -shard Master', shell=True, cwd=path_dst_).wait(1)  # 开启地上
            Popen('screen -dmS ' + screen_name_cave +
                  ' ./dontstarve_dedicated_server_nullrenderer -console -cluster ' + dir_cluster +
                  ' -shard Caves', shell=True, cwd=path_dst_).wait(1)  # 开启地下
        if times <= 5:
            print(' ' * 20 + 'mod {} 更新完成'.format('、'.join(need_update_name)))
    except Exception as e:
        print(' ' * 19, 'update_mod函数出错')
        print(' ' * 19, e)
    finally:
        t = 1800 - (time() - time_start)
        if t <= 0:
            t = 1800
        Timer(t, update_mod, [path_cluster_, path_dst_, tick, tick2]).start()  # 间隔t秒后再次执行该函数


def getpath():  # 自动检测所需路径
    str_dst_bin = 'bin'
    str_dst_bin_verify = 'dontstarve_dedicated_server_nullrenderer'
    str_steamcmd = 'steamcmd'
    str_steamcmd_verify = 'steamcmd.sh'
    str_cluster = 'DoNotStarveTogether'

    path_user = expanduser('~')
    # 定义默认路径
    path_dst_bin = pathjoin(path_user, "Steam/steamapps/common/Don't Starve Together Dedicated Server/bin")
    path_steamcmd = pathjoin(path_user, 'steamcmd')
    path_cluster = pathjoin(path_user, '.klei/DoNotStarveTogether/MyDediServer')

    try:
        if len(argv) == 1:
            steamcmd_code = 0
            path_dst_bin_list, version_list, cluster_list = [], [], []
            for rt, dirs, files in walk(expanduser('~')):
                if str_dst_bin in rt and str_dst_bin_verify in files:
                    path_dst_bin_list.append(rt)
                if str_steamcmd in rt and str_steamcmd_verify in files:
                    path_steamcmd = rt
                    steamcmd_code = 1
                if str_cluster == rt.split('/')[-1]:
                    for i in listdir(rt):
                        if isdir(pathjoin(rt, i)):
                            cluster_list.append((rt, i))

            if len(path_dst_bin_list) == 1:
                path_dst_bin = path_dst_bin_list[0]
                print('饥荒服务器路径：' + path_dst_bin)
            elif len(path_dst_bin_list) > 1:
                for i in path_dst_bin_list:
                    path_version_ = pathjoin(dirname(i), 'version.txt')
                    if exists(path_version_):
                        with open(path_version_, 'r', encoding='utf-8') as f:
                            data = f.read()
                            pattern = recompile('[0-9]{6}')
                            version_list.append((pattern.search(data).group(0), i))
                version_list.sort(key=lambda x: x[0], reverse=True)
                path_dst_bin = version_list[0][1]
                print('饥荒服务器路径：' + path_dst_bin)
            else:
                print('未检测到饥荒程序文件夹，请检查是否安装饥荒服务器或登录用户是否正确')
                print('将使用默认路径：' + path_dst_bin)
            if steamcmd_code == 1:
                print('steamcmd路径：' + path_steamcmd)
            else:
                print('未检测到steamcmd文件夹，请检查是否安装steamcmd或登录用户是否正确')
                print('将使用默认路径：' + path_steamcmd)

            if len(cluster_list) == 1:
                path_cluster = pathjoin(cluster_list[0][0], cluster_list[0][1])
                print('存档路径：' + path_cluster)
            elif len(cluster_list) > 1:
                path_cluster_list = []
                for i in range(len(cluster_list)):
                    verifyfile_list = listdir(pathjoin(cluster_list[i][0], cluster_list[i][1]))
                    if 'cluster.ini' in verifyfile_list and 'cluster_token.txt' in verifyfile_list:
                        path_cluster_list.append(pathjoin(cluster_list[i][0], cluster_list[i][1]))
                if len(path_cluster_list) == 1:
                    path_cluster = path_cluster_list[0]
                    print('存档路径：' + path_cluster)
                else:
                    print('游戏文件夹内检测到多个可能是存档的文件夹，如下。请清理无关文件夹')
                    for i in path_cluster_list:
                        print(i)
                    print('将使用第一个路径：' + path_cluster_list[0])
                    path_cluster = path_cluster_list[0]
            else:
                print('未检测到游戏文件夹')
                print('将使用默认路径：' + path_cluster)
        else:
            path_cluster = argv[1]
            steamcmd_code = 0
            path_dst_bin_list, version_list, cluster_list = [], [], []
            for rt, dirs, files in walk(expanduser('~')):
                if str_dst_bin in rt and str_dst_bin_verify in files:
                    path_dst_bin_list.append(rt)
                if str_steamcmd in rt and str_steamcmd_verify in files:
                    path_steamcmd = rt
                    steamcmd_code = 1

            if len(path_dst_bin_list) == 1:
                path_dst_bin = path_dst_bin_list[0]
                print('饥荒服务器路径：' + path_dst_bin)
            elif len(path_dst_bin_list) > 1:
                for i in path_dst_bin_list:
                    path_version_ = pathjoin(dirname(i), 'version.txt')
                    if exists(path_version_):
                        with open(path_version_, 'r', encoding='utf-8') as f:
                            data = f.read()
                            pattern = recompile('[0-9]{6}')
                            version_list.append((pattern.search(data).group(0), i))
                version_list.sort(key=lambda x: x[0], reverse=True)
                path_dst_bin = version_list[0][1]
                print('饥荒服务器路径：' + path_dst_bin)
            else:
                print('未检测到饥荒程序文件夹，请检查是否安装饥荒服务器或用户是否正确')
                print('将使用默认路径：' + path_dst_bin)
            if steamcmd_code == 1:
                print('steamcmd路径：' + path_steamcmd)
            else:
                print('未检测到steamcmd文件夹，请检查是否安装steamcmd或用户是否正确')
                print('将使用默认路径：' + path_steamcmd)
        return path_cluster, path_dst_bin, path_steamcmd
    except Exception as e:
        print(' ' * 19, e)
        print(' ' * 20 + '自动检索路径错误，即将退出')
        exit()


if __name__ == "__main__":
    screen_name_master = 'DST_MASTER'  # 地上世界的screen作业名
    screen_name_cave = 'DST_CAVES'  # 地下世界的screen作业名
    path = abspath(dirname(__file__))  # 获取本文件所在目录绝对路径
    dstpaths = getpath()

    # 自定义参数
    time_to_reset = 24  # 超时重置时间(单位/hour)
    day_to_change = 40  # 转为无尽的天数
    # 自定义参数

    # 自动备份
    chatlog(dstpaths[0], 8)  # (存档位置， 备份间隔时间(单位/min))

    # 检测是否需要重置 (删除下行将不会再检测是否需要重置
    reset(dstpaths[0], dstpaths[1], time_to_reset)  # (存档位置， 服务器程序位置， 超时重置时间(单位/hour))

    sleep(20)  # 错开运行时间
    # 检测是否需要转为无尽 (删除下行将不会再检测是否需要转为无尽
    for_endless(dstpaths[0], dstpaths[1], day_to_change, time_to_reset)  # (存档位置， 服务器程序位置， 转为无尽的天数， 超时重置时间(单位/hour))

    sleep(20)  # 错开运行时间
    # 检测是否存在并执行更新 (删除下行将不会再检测是否存在并执行更新
    update(dstpaths[0], dstpaths[1], dstpaths[2])
    # (存档位置， 服务器程序位置， steamcmd位置)

    sleep(20)  # 错开运行时间
    # 检测是否存在并执行mod更新 (删除下行将不会再检测是否存在并执行mod更新
    update_mod(dstpaths[0], dstpaths[1])
    # (存档位置， 服务器程序位置)
