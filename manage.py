#!/usr/bin/env python

import argparse
import errno
import os
import platform
import subprocess
import sys
try:
    from urllib.request import urlopen
except ImportError:
    from urllib import urlopen

PROJECT = 'RulzUrDB'
PYTHON_REQUIRED_VERSION = 3.4
VENV_NAME = '.venv'

RIAK_PORT = 49098

TOP_DIR = os.path.dirname(os.path.realpath(__file__))
PYTHON_EXEC = sys.executable
PYTHON_VERSION = float('%s.%s' % tuple(sys.version_info[0:2]))

parser = argparse.ArgumentParser(
    description='Management of development environment for %s.' % PROJECT,
)


def install_docker_osx():
    def install_brew():
        try:
            subprocess.check_call(
                ['ruby', '-e'],
                stdin=os.popen(
                    urlopen(
                        'https://raw.github.com/Homebrew/homebrew/go/install')
                    .read()
                )
            )
        except subprocess.CalledProcessError as e:
            parser.error('\x1b[0;31m'
                         'An error occurs when installing brew aborting: \n'
                         '%s'
                         '\x1b[0m' % e)

    try:
        subprocess.check_call(['brew', 'update'])
        subprocess.check_call(['brew', 'install', 'docker', 'boot2docker'])
    except subprocess.CalledProcessError:
        parser.error('\x1b[0;31m'
                     'An error occurs during the installation of boot2docker '
                     'and docker'
                     '\x1b[0m')
    except OSError:
        install_brew()
        install_docker_osx()

    export_file = (
        os.environ['HOME'] +
        os.sep +
        '.zprofile' if 'zsh' in os.environ['SHELL'] else '.profile')
    export_file_tmp = export_file + '.tmp'
    with open(export_file, 'w+') as f_in, open(export_file_tmp, 'w') as f_out:
        export = 'export DOCKER_HOST="tcp://127.0.0.1:4243"' + os.linesep
        for line in f_in:
            if 'DOCKER_HOST' in line:
                f_out.write(export)
                f_out.write(f_in.read())
                break
            f_out.write(line)
        else:
            f_out.write(export)
    os.rename(export_file_tmp, export_file)

    try:
        subprocess.check_call(
            ['boot2docker', 'init']
        )
        for i in range(49000, 49900):
            subprocess.check_call(
                ['VBoxManage', 'modifyvm', 'boot2docker-vm', '--natpf1',
                 "tcp-port%d,tcp,,%d,,%d" % (i, i, i)]
            )
            subprocess.check_call(
                ['VBoxManage', 'modifyvm', 'boot2docker-vm', '--natpf1',
                 "udp-port%d,udp,,%d,,%d" % (i, i, i)]
            )

    except subprocess.CalledProcessError:
        parser.error('\x1b[0;31m'
                     'An error occurs during the initialization of '
                     'boot2docker'
                     '\x1b[0m')

    print('\x1b[0;32m'
          'docker and boot2docker have been installed on your computer, '
          'you need to reopen a terminal to have the commands available'
          '\x1b[0m')


def install_docker_ubuntu():
    try:
        subprocess.check_call(
            ['sh'],
            stdin=os.popen(urlopen('https://get.docker.io/').read())
        )
    except subprocess.CalledProcessError as e:
        parser.error('\x1b[0;31m'
                     'An error occurs aborting: \n'
                     '%s'
                     '\x1b[0m' % e)


def install_docker():
    if platform.system() == 'Darwin':
        install_docker_osx()
    elif platform.dist()[0] == 'Ubuntu' and float(platform.dist()[1]) > 12.04:
        install_docker_ubuntu()
    else:
        print('\x1b[0;31m'
              'The docker installation is only available on OSX and Ubuntu >= '
              '12.04, docker installation will be skipped.'
              '\x1b[0m')


def install(options):
    if options['all'] or not any(options.values()):
        install_docker()
        options = options.fromkeys(options, False)

    if options['docker']:
        install_docker()


def docker(options):
    def docker_error(error):
        if error.errno == errno.ENOENT:
            parser.error('\x1b[0;31m'
                         'Docker does not seem to be installed on your computer'
                         ', please fix this and rerun the command'
                         '\x1b[0m')

    if options['clean']:
        try:
            processes = subprocess.check_output(['docker', 'ps', '-a', '-q'])
            for process in processes.split():
                subprocess.call(['docker', 'stop', process])
                subprocess.call(['docker', 'rm', process])
        except OSError as err:
            docker_error(err)

    if options['build']:
        try:
            subprocess.call([
                'docker', 'build', '-t=%s' % PROJECT, '-rm=true', '.'
            ])
        except OSError as err:
            docker_error(err)
    if options['run']:
        try:
            subprocess.call([
                'docker', 'run', '-d', '-p', '8098:%d' % RIAK_PORT, PROJECT
            ])
        except OSError as err:
            docker_error(err)

    if options['ssh']:
        try:
            subprocess.call([
                'docker', 'run', '-p', '8098:%d' % RIAK_PORT, '-i', '-t',
                PROJECT, '/bin/bash'
            ])
        except OSError as err:
            docker_error(err)

if __name__ == '__main__':
    subparsers = parser.add_subparsers()

    # install subparser
    parser_install = subparsers.add_parser(
        'install',  help='Install the development environment of the project',
    )
    parser_install.set_defaults(func=install)
    parser_install.add_argument(
        '-a', '--all',
        help='Install all the development environment of %s' % PROJECT,
        action='store_true'
    )

    parser_install.add_argument(
        '-d', '--docker',
        help='Install boot2docker and docker binding on the computer',
        action='store_true'
    )

    # docker subparser
    parser_docker = subparsers.add_parser(
        'docker',  help='Manage docker specific commands',
    )
    parser_docker.set_defaults(func=docker)

    parser_docker.add_argument(
        '-b', '--build',
        help='Build the docker container for %s' % PROJECT,
        action='store_true'
    )

    parser_docker.add_argument(
        '-c', '--clean',
        help='Stops and clean all dockers daemon',
        action='store_true'
    )

    parser_docker.add_argument(
        '-r', '--run',
        help='Run the docker container associated with %s' % PROJECT,
        action='store_true'
    )

    parser_docker.add_argument(
        '-s', '--ssh',
        help='Connect to the %s docker container through ssh' % PROJECT,
        action='store_true'
    )

    args = parser.parse_args()
    args.func(vars(args))
