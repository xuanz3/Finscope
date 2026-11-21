import os

application = os.path.abspath(defines['app'])
appname = os.path.basename(application)
format = 'UDZO'
files = [application]
symlinks = {'Applications': '/Applications'}
hide_extensions = [appname]
background = 'builtin-arrow'
window_rect = ((100, 100), (640, 280))
default_view = 'icon-view'
icon_size = 112
text_size = 13
icon_locations = {appname: (140, 120), 'Applications': (500, 120)}
show_status_bar = False
show_toolbar = False
show_sidebar = False
show_pathbar = False
show_tab_view = False
