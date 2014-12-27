#Jeff Ho
#Need Twitter account & Twitter Developers
#Recommend running on Ipython Notebook


import twitter
import io
import json
import pymongo
import sys
import datetime
import time



#Fill in your login info
def oauth_login():    
    CONSUMER_KEY = "..."
    CONSUMER_SECRET = "..."
    OAUTH_TOKEN = "..."
    OAUTH_TOKEN_SECRET = "..."
    
    auth = twitter.oauth.OAuth(OAUTH_TOKEN, OAUTH_TOKEN_SECRET, CONSUMER_KEY, CONSUMER_SECRET)
    
    twitter_api = twitter.Twitter(auth=auth)
    return twitter_api


twitter_api = oauth_login()    
print "Twitter API:" + str( twitter_api )



print ""
print "#######################################################################################################################"
print ""



def twitter_search(twitter_api, q, max_results=10000, **kw):
    
    search_results = twitter_api.search.tweets(q=q, count=100, **kw)
    
    statuses = search_results['statuses']
    
    for _ in range(10000):
        try:
            next_results = search_results['search_metadata']['next_results']
        except KeyError, e: 
            break

            
        kwargs = dict([ kv.split('=') 
                        for kv in next_results[1:].split("&") ])
        
        search_results = twitter_api.search.tweets(**kwargs)
        statuses += search_results['statuses']
        
        if len(statuses) > max_results: 
            break
            
    return statuses



def save_json(filename, data):
    with io.open('/Users/Jeff/Desktop/test.txt'.format(filename), 
                 'w', encoding='utf-8') as f:
        f.write(unicode(json.dumps(data, ensure_ascii=False)))

   
        
def load_json(filename):
    with io.open('/Users/Jeff/Desktop/test.txt'.format(filename), 
                 encoding='utf-8') as f:
        return f.read()

    
    
def save_to_mongo(data, mongo_db, mongo_db_coll, **mongo_conn_kw):
    
    client = pymongo.MongoClient(**mongo_conn_kw)

    db = client[mongo_db]
    
    coll = db[mongo_db_coll]

    return coll.insert(data)



def load_from_mongo(mongo_db, mongo_db_coll, return_cursor=False, criteria=None, projection=None, **mongo_conn_kw):
    
    client = pymongo.MongoClient(**mongo_conn_kw)
    db = client[mongo_db]
    coll = db[mongo_db_coll]
    
    if criteria is None:
        criteria = {}
    
    if projection is None:
        cursor = coll.find(criteria)
    else:
        cursor = coll.find(criteria, projection)
    
    if return_cursor:
        return cursor
    else:
        return [ item for item in cursor ]


    
   
    
q = "$ALSK"   # <--- Put in the key word( anything you feel interested, w/ or w/o $ & # )

results = twitter_search(twitter_api, q, max_results=10000)

#Count the number of results
print "Number of results is " + str(len(results))

#Print results
print json.dumps( results, indent=1 )

#Save results as a txt file
save_json( q, results )

#Load the txt file
print load_json( q ) 

#Save results to MongoDB
save_to_mongo( results, 'search_results', q )

#Load the results from MongoDB
print load_from_mongo( 'search_results', q )



#END
