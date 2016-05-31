import os,sys
from sqlite3 import dbapi2 as sqlite3
from flask import Flask, request, session, g, redirect, url_for, abort, \
     render_template, flash, send_file

from flask.ext.responses import json_response

from subprocess import PIPE, call, check_output
from subprocess import Popen

from tempfile import mkdtemp, TemporaryFile, mkstemp
from shutil import copyfile

import random, string, json
from base64 import b64decode
import tarfile

# create our little application :)
app = Flask(__name__)

# Load default config and override config from an environment variable
app.config.update(dict(
    DATABASE=os.path.join('/data/raspis.db'),
    DEBUG=True,
    SECRET_KEY='fds623fe24fgl4d',
    USERNAME='admin',
    PASSWORD='default'
))
app.config.from_envvar('PROVIDER_SETTINGS', silent=True)

def connect_db():
    """Connects to the specific database."""
    rv = sqlite3.connect(app.config['DATABASE'])
    rv.row_factory = sqlite3.Row
    return rv


def init_db():
    """Initializes the database."""
    db = get_db()
    with app.open_resource('schema.sql', mode='r') as f:
        db.cursor().executescript(f.read())
    db.commit()

def query_db(query, args=(), one=False):
    """Queries the database and returns a list of dictionaries."""
    cur = get_db().execute(query, args)
    rv = cur.fetchall()
    return (rv[0] if rv else None) if one else rv

#@app.cli.command('initdb')
def initdb_command():
    """Creates the database tables."""
    init_db()
    print('Initialized the database.')

@app.route("/setup")
def setup():
    init_db()
    flash("Database Created")
    return redirect(url_for('show_entries'))


def get_db():
    """Opens a new database connection if there is none yet for the
    current application context.
    """
    if not hasattr(g, 'sqlite_db'):
        g.sqlite_db = connect_db()
    return g.sqlite_db


@app.teardown_appcontext
def close_db(error):
    """Closes the database again at the end of the request."""
    if hasattr(g, 'sqlite_db'):
        g.sqlite_db.close()

@app.route('/')
def show_entries():
    db = get_db()
    entries = query_db('select id, mac from devices')
    return render_template('show_entries.html', entries=entries)

def random_string(n):
    return ''.join(random.SystemRandom().choice(string.ascii_letters + string.digits + '!@#$%^&*()[]:;|?/><.,~-_=+') for _ in range(n))

def put_to_file(s,f):
    with open(f, 'w') as f:
        f.write(s)

@app.route('/<mac>', methods=['DELETE'])
def del_entry(mac):
    """ Delete the entry and TODO - revoke its certificate """
    db = get_db()
    entry = query_db('selete from devices where mac = ?', True)
    flash("Device removed")
    return redirect(url_for('show_entries'))


@app.route('/<mac>', methods=['GET'])
def get_entry(mac):
    db = get_db()
    entry = query_db('select * from devices where mac = ?', [mac], True)
    if entry is None:
        abort(404)

    # turn this into a set of configs, tar it up, and send the results

    ## first template the nifi.properties
    nifi_props = render_template('nifi.properties.in', passwords = {
        'truststorePasswd': entry["truststorePasswd"],
        'keyPasswd': entry["keyPasswd"],
        'keystorePasswd': entry["keystorePasswd"],
        'propertyKey': random_string(32)
        })

    d = mkdtemp('config', entry['name'])

    put_to_file(nifi_props, d+'/nifi.properties')

    ## put the keystores and truststores in place
    put_to_file(b64decode(entry['trustStore']), d+'/truststore.jks')
    put_to_file(b64decode(entry['serverKeystore']), d+'/keystore.jks')
    put_to_file(b64decode(entry['clientKeystore']), d+'/client.keystore.jks')

    # Add in config template overlay
    for root, dirnames, filenames in os.walk('/data/configs'):
        for filename in filenames:
            copyfile(os.path.join(root, filename), os.path.join(d,root[len('/data/configs/'):],filename))

    def reset(tarinfo):
        tarinfo.uid = tarinfo.gid = 0
        tarinfo.uname = tarinfo.gname = "root"
        tarinfo.name = tarinfo.name[len(d):]
        return tarinfo

    # tar up the directory and send it to the client

    f = mkstemp()[1]
    tar = tarfile.open(f, "w:gz")
    tar.add(d,filter=reset)
    tar.close()
    response = send_file(f, as_attachment=True, attachment_filename='nifi-config.tar.gz')

    return response

@app.route('/', methods=['POST'])
def add_entry():
    mac = request.form['mac']
    # use 'pi' + last 3 digits of mac address for DNS
    name = "pi" + "".join(mac.split(":")[3:])
    id = random_string(32)

    cmd = ['./makecert0.sh', mac, name, random_string(32), random_string(32)]

    process = Popen(cmd, stdout=PIPE)
    output = process.stdout.read()
    exit_code = process.wait()

    print output
    results = json.loads(output)

    # unbase64
    clientKeystore = results['clientKeystore']
    serverKeystore = results['serverKeystore']
    trustStore = results['trustStore']
    keyPasswd = results['keyPasswd']
    keystorePasswd = results['keystorePasswd']
    truststorePasswd = results['truststorePasswd']

    db = get_db()
    db.execute('insert into devices (id, mac, name, keystorePasswd, truststorePasswd, keyPasswd, trustStore, clientKeystore, serverKeystore) values (?, ?, ?, ?, ?, ?, ?, ?, ?)',
               [id, mac, name, keystorePasswd, truststorePasswd, keyPasswd, trustStore, clientKeystore, serverKeystore])
    db.commit()

    flash("Device added")
    return redirect(url_for('show_entries'))
