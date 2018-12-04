from navio.builder import task, nsh, sh
from navio.travis import Travis
import os

travis = Travis().is_travis()
branch = Travis().branch()

Config = {
  'master': {
    'docker_tag': 'latest',
  },
}

@task()
def setup():
  nsh.docker('login', '-u', os.environ.get('DOCKER_HUB_USER'), '-p', os.environ.get('DOCKER_HUB_PASS'))

@task()
def build():
  nsh.docker('build --rm=true -t alpine-postgres-postgis .'.split(' '))

@task(build)
def push():
  if os.environ.get('TRAVIS_PULL_REQUEST', 'false') == 'true':
    print("Skipping docker image push for push requests")
    return

  if branch in Config and not Travis().is_tag():
    nsh.docker.tag(
        'alpine-postgres-postgis:latest', 
        'navioonline/alpine-postgres-postgis:{tag}'.format(Config[branch]['docker_tag'])
      )

  if not Travis().is_pull_request() and Travis().is_tag():
    nsh.docker.tag(
        'alpine-postgres-postgis:latest', 
        'navioonline/alpine-postgres-postgis:{tag}'.format(Travis().tag())
      )

@task()
def check_uncommited():
    result = sh.git('status', '--porcelain', '--untracked-files=no')
    if result:
        raise Exception('There are uncommited files')

@task()
def update_version(ver=None):
    with open('meta.py', 'r') as f:
        file_str = f.read()

    if not ver:
        regexp = re.compile(r'__version__\s*\=\s*\"([\d\w\.\-\_]+)\"\s*')
        m = regexp.search(file_str)
        if m:
            ver = m.group(1)

    minor_ver = int(ver[ver.rfind('.') + 1:])
    ver = '{}.{}'.format(ver[:ver.rfind('.')], minor_ver + 1)

    file_str = re.sub(
        r'__version__\s*\=\s*\"([\d\w\.\-\_]+)\"\s*',
        r'__version__ = "{}"\n'.format(ver),
        file_str)

    with open('meta.py', 'w') as f:
        f.write(file_str)

    nsh.git('commit', 'meta.py', '-m', 'Version updated to {}'.format(ver))


@task()
def create_tag():
    nsh.git('tag', '-a', '-m', 'Tagging version {}'.format(ver), ver)


@task()
def push_git():
    nsh.git('push', '--verbose')
    nsh.git('push', '--tags', '--verbose')


@task()
def release(ver=None):
    check_uncommited()
    update_version(ver)
    create_tag()
    push_git()