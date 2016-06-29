#!/usr/bin/env python2.7

import os
import decimal
import tinys3
import flask.json
from sqlalchemy import *
from flask import Flask, request, render_template, g, redirect, Response, session, jsonify, abort
from server.config import *
from server.data_access.user_data_access import *
from server.data_access.bike_data_access import *
from server.data_access.user_msg_access import *
from server.data_access.user_request_access import *
from werkzeug.utils import secure_filename


class MyJSONEncoder(flask.json.JSONEncoder):

    def default(self, obj):
        if isinstance(obj, decimal.Decimal):
            # Convert decimal instances to strings.
            return float(obj)
        return super(MyJSONEncoder, self).default(obj)

tmpl_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates')
application = api = Flask(__name__, template_folder=tmpl_dir)
application.json_encoder = MyJSONEncoder
application.config['ALLOWED_EXTENSIONS'] = set(['png', 'jpg', 'jpeg', 'gif'])
application.config['UPLOAD_FOLDER'] = 'uploads/'

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1] in application.config['ALLOWED_EXTENSIONS']

# set the secret key.  keep this really secret:
application.secret_key = secret_key
DATABASEURI = database_uri
engine = create_engine(DATABASEURI)

@application.before_request
def before_request():
    """
    This function is run at the beginning of every web request
    (every time you enter an address in the web browser).
    We use it to setup a database connection that can be used throughout the request.

    The variable g is globally accessible.
    """
    # if ('uid' not in session) and (request.endpoint != "login") and (request.endpoint != "userLogin"):
    #     return redirect('/login')
    try:
        g.conn = engine.connect()
    except:
        print "uh oh, problem connecting to database"
        import traceback; traceback.print_exc()
        g.conn = None

@application.teardown_request
def teardown_request(exception):
    """
    At the end of the web request, this makes sure to close the database connection.
    If you don't, the database could run out of memory!
    """
    try:
        g.conn.close()
    except Exception as e:
        pass

@application.route('/')
def index():
    return "Ready!"

######## User ########
@application.route('/login')
def login():  # test view
    return render_template("login.html")

@application.route('/view/register')
def reg():  # test view
    return render_template('register.html')

@application.route('/userLogin', methods=['POST'])
def userLogin():
    username = request.form['username']
    password = request.form['password']
    uda = UserDataAccess(g.conn)
    output = uda.authorize(username, password)

    if output['status']:
        user = output['result']['user']
        session['uid'] = user['uid']
        session['username'] = user['username']
        session['firstname'] = user['firstname']
        session['lastname'] = user['lastname']
        session['email'] = user['email']

    return jsonify(output)

@application.route('/register', methods=['POST'])
def register():
    username = request.form['username']
    password = request.form['password']
    email = request.form['email']
    firstname = request.form['firstname']
    lastname = request.form['lastname']
    uda = UserDataAccess(g.conn)
    output = uda.register(username, password, firstname, lastname, email)

    return jsonify(output)


######## User bikes ########
@application.route('/getAllBikes')
def get_all_bikes():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        bda = BikeDataAccess(g.conn)
        output = bda.get_bikes_by_user_id(session['uid'])

        return jsonify(output)

@application.route('/addBike', methods=['POST'])
def add_bike():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        bda = BikeDataAccess(g.conn)
        user_id = session['uid']
        model = request.form['model']
        available = request.form['available']
        price = request.form['price']
        address = request.form['address']
        state = request.form['state']
        city = request.form['city']
        postcode = request.form['postcode']
        country = request.form['country']
        lat = request.form['lat']
        lon = request.form['lon']
        details = request.form['details']
        output = bda.add_bike(user_id, model, available, price, address, state, city, postcode, country, lat, lon, details)

        return jsonify(output)

@application.route('/view/upload')
def upload_view():  # test view
    return render_template("upload.html")

@application.route('/upload/<bid>', methods=['POST'])
def upload(bid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        photo_file = request.files['file']
        bid = int(bid)
        if photo_file and allowed_file(photo_file.filename):
            filename = secure_filename(photo_file.filename)
            photo_file.save(os.path.join(application.config['UPLOAD_FOLDER'], filename))

            f = open(os.path.join(application.config['UPLOAD_FOLDER'], filename), 'rb')
            conn = tinys3.Connection(S3_ACCESS_KEY, S3_SECRET_KEY, tls=True, endpoint='s3-us-west-2.amazonaws.com')
            conn.upload(filename, f, 'bike-share-comse6998')

            url = S3_BUCKET_URL + filename
            bda = BikeDataAccess(g.conn)
            output = bda.add_photo(url, bid)

            return jsonify(output)
        else:
            output = {
                'message': 'Unsupported file format',
                'status': False
            }

            return jsonify(output)

@application.route('/removePhoto/<pid>')
def remove_photo(pid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        bda = BikeDataAccess(g.conn)
        output = bda.remove_photo(pid)

        return jsonify(output)

@application.route('/getBikePhotos/<bid>')
def get_bike_photos(bid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        bda = BikeDataAccess(g.conn)
        output = bda.get_bike_photos(bid)

        return jsonify(output)

@application.route('/editBike/<bid>', methods=['POST'])
def edit_bike(bid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        bid = int(bid)
        bda = BikeDataAccess(g.conn)
        address = request.form['address']
        state = request.form['state']
        city = request.form['city']
        postcode = request.form['postcode']
        country = request.form['country']
        lat = request.form['lat']
        lon = request.form['lon']
        model = request.form['model']
        price = request.form['price']
        details = request.form['details']
        available = request.form['available']
        output = bda.edit_bike(bid, address, state, city, postcode, country, lat, lon, model, price, details, available)

        return jsonify(output)

@application.route('/getBike/<bid>')
def get_bike(bid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        bid = int(bid)
        bda = BikeDataAccess(g.conn)
        output = bda.get_bike(bid)

        return jsonify(output)

######## Get available bikes ########
@application.route('/getAvailableBikes')
def get_available_bikes():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        uid = session['uid']
        bda = BikeDataAccess(g.conn)
        lon = request.args.get('lon')
        lat = request.args.get('lat')
        distance = request.args.get('distance')
        from_date = request.args.get('from_date').replace(' ', '+')
        to_date = request.args.get('to_date').replace(' ', '+')
        # from_price = request.form['from_price']
        # to_price = request.form['to_price']
        output = bda.get_available_bikes(uid, lon, lat, distance, from_date, to_date)

        return jsonify(output)


######## User  profile ########
@application.route('/getProfile')
def get_profile():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        uda = UserDataAccess(g.conn)
        user_id = session['uid']
        output = uda.get_user(user_id)

        return jsonify(output)

@application.route('/updateProfile', methods=['POST'])
def update_profile():
    method = request.form['method']
    if not session or 'uid' not in session:
        return abort(403)
    else:
        uda = UserDataAccess(g.conn)
        if method == 'changePassword':
            user_id = session['uid']
            old_password = request.form['old_password']
            new_password = request.form['new_password']
            output = uda.change_password(user_id, old_password, new_password)

            return jsonify(output)
        else:
            user_id = session['uid']
            email = request.form['email']
            firstname = request.form['firstname']
            lastname = request.form['lastname']
            output = uda.update_profile(user_id, firstname, lastname, email)

            return jsonify(output)


######## Message ########
@application.route('/sendMsg', methods=['POST'])
def send_message():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        uid = session['uid']
        rid = request.form['rid']
        # uid2 = request.form['toWhom']
        message = request.form['message']

        uma = UserMsgAccess(g.conn)
        output = uma.send_message(uid, rid, message)

    return jsonify(output)

@application.route('/showMessages/<rid>')
def show_messages(rid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        uid = session['uid']

        uma = UserMsgAccess(g.conn)
        output = uma.show_messages(rid)

        return jsonify(output)


######## Request ########
@application.route('/getRequests')
def get_requests():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        ura = UserRequestAccess(g.conn)
        user_id = session['uid']
        output = ura.get_requests(user_id)

        return jsonify(output)

@application.route('/getMyRequests')
def get_my_requests():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        ura = UserRequestAccess(g.conn)
        user_id = session['uid']
        output = ura.get_my_requests(user_id)

        return jsonify(output)

@application.route('/getRequest/<rid>')
def get_request(rid):
    if not session or 'uid' not in session:
        return abort(403)
    else:
        ura = UserRequestAccess(g.conn)
        rid = int(rid)
        output = ura.get_request_by_id(rid)

        return jsonify(output)

@application.route('/sendRequest', methods=['POST'])
def send_request():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        user_id = session['uid']
        bid = request.form['bid']
        from_date = request.form['from_date'].replace(' ', '+')
        to_date = request.form['to_date'].replace(' ', '+')
        message = request.form['message']

        ura = UserRequestAccess(g.conn)
        output = ura.send_request(user_id, bid, from_date, to_date, message)

        return jsonify(output)

@application.route('/respondRequest', methods=['POST'])
def respond_request():
    if not session or 'uid' not in session:
        return abort(403)
    else:
        user_id = session['uid']
        rid = request.form['rid']
        respond = request.form['respond']

        ura = UserRequestAccess(g.conn)
        output = ura.respond_request(rid, respond)

        return jsonify(output)


if __name__ == "__main__":

    # @click.command()
    # @click.option('--debug', is_flag=True)
    # @click.option('--threaded', is_flag=True)
    # @click.argument('HOST', default='0.0.0.0')
    # @click.argument('PORT', default=5000, type=int)
    # def run(debug, threaded, host, port):
    #     """
    #         This function handles command line parameters.
    #         Run the server using:
    #         python server.py
    #
    #         Show the help text using:
    #
    #         python server.py --help
    #
    #     """
    #
    #     HOST, PORT = host, port
    #     print "running on %s:%d" % (HOST, PORT)
    #     app.run(host=HOST, port=PORT, debug=True, threaded=threaded)
    #
    # run()
    application.debug = True
    application.run(host='0.0.0.0')