import json


class DictionaryOperationException(Exception):
    pass


class ExtendDictionary(object):
    def update_dictionary(self, dictionary, *args):
        def _sub(v):
            if v.startswith('${') and v.endswith('}'):
                return int(v[2:-1])
            elif v.startswith("u'") and v.endswith("'"):
                return unicode(v[2:-1])
            return v
        for arg in args:
            k, v = arg.split("=")
            try:
                v = json.loads(v)
                for key, value in v.iteritems():
                    v[key] = _sub(value)
            except Exception as e:
                if isinstance(v, str) or isinstance(v, unicode):
                    v = _sub(v)
            if k in dictionary:
                dictionary[k] = v
            else:
                dictionary.update({k: v})
        dictionary=json.dumps(dictionary)

    def convert_to_dictionary(self, string):
        """
            Method converts input string to dictionary
        """
        return json.loads(string)
   
    def convert_to_json(self, dictionary):
        """
            Method converts input dictionary to json
        """
        return json.dumps(dictionary)

