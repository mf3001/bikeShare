#from bike_data_access import *
# from server.config import *
from sqlalchemy import *
from user_msg_access import *
from user_request_access import *


DATABASEURI = 'postgresql://yc3171:65676567@cloudproject.c0amxekhefct.us-west-2.rds.amazonaws.com:5432/bikesharing'
engine = create_engine(DATABASEURI)
conn = None
try:
    conn = engine.connect()
except:
    print "uh oh, problem connecting to database"
    import traceback; traceback.print_exc()
    conn = None

ura = UserRequestAccess(conn)
print ura.respondRequest('3', 'Approved')