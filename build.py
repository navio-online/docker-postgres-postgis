from navio.builder import task, nsh, sh
from navio.travis import Travis

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

  if branch in Config:
    nsh.docker.tag(
        'alpine-postgres-postgis:latest', 
        'navioonline/alpine-postgres-postgis:{tag}'.format(Config[branch]['docker_tag'])
      )

  if not Travis().is_pull_request() and Travis().is_tag():
    nsh.docker.tag(
        'alpine-postgres-postgis:latest', 
        'navioonline/alpine-postgres-postgis:{tag}'.format(Travis().tag())
      )
