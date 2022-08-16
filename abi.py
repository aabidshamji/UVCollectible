import json

class ABIFormatter:

    def __init__(self, abi_path):
        f = open(abi_path)
        token = json.load(f)
        self.token = token
        
        abi = token['abi']
        self.abi = abi 

    
    def get_input_string(self, function):
        data = function['inputs']
        if len(data) == 0: return 'NONE'
        s = ''
        for i in data:
            s += f" {i['name']} ({i['type']}),"
        if s[-1] == ',': s = s[:-1]
        return s

    def get_output_string(self, function):
        if 'outputs' not in function.keys(): return ''
        data = function['outputs']
        s = '=> '
        if len(data) == 0: return s + 'NONE'
        for i in data:
            if len(i['name']) > 0:
                s += f" {i['name']} ({i['type']}),"
            else:
                s += f"{i['type']}"
        return s

    def print_functions(self):
        for function in self.abi:
            if 'name' in function.keys():
                function_type = function['type']
                if function_type == 'function':
                    function_type += ', ' + function['stateMutability']
                print(
                    function['name'], 
                    f"({function_type}):", 
                    self.get_input_string(function),
                    self.get_output_string(function)
                )
            else:
                print(
                    'Constructor:',
                    self.get_input_string(function)
                )
                