
def fix_fc_keyword():
    from waflib.Tools.fc import fc
    def keyword(self):
        return 'Compiling'
    fc.keyword = keyword

