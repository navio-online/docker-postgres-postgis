from navio.builder import task, nsh, sh


@task()
def build():
  nsh.docker('build --rm=true -t postgis .'.split(' '))

