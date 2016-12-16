import random
import math
random.seed('russia-team-2016/data')

class TestGen:
    def __init__(self, number):
        self.test_number = number - 1

    def generate_random_array(self, n, minvalue, maxvalue):
        a = []
        for i in range(n):
            a.append(random.randint(minvalue, maxvalue))
        return a

    def generate_max_tests(self, maxh, maxw, maxn, alphas):
        h = maxh
        w = maxw
        n = maxn
        mn = min(n, 1000)
        a = self.generate_random_array(mn, 0, h - 1)
        b = self.generate_random_array(mn, 0, w - 1)
        c = self.generate_random_array(mn, 0, h - 1)
        d = self.generate_random_array(mn, 0, w - 1)
        s = ['' for _ in range(n)]
        for j in range(n):
            s[j] = alphas[random.randint(0, len(alphas) - 1)]
        s = ''.join(s)
        self.print_test(h, w, s, [a, b, c, d])

    def generate_third_group_of_tests(self):
        for i in range(10):
            h = random.randint(1, 10)
            w = random.randint(1, 10)
            n = random.randint(0, 100)
            minn = 2
            maxn = n
            if n <= 2:
                minn = n
            a = self.generate_random_array(random.randint(minn, maxn), 0, h - 1)
            b = self.generate_random_array(random.randint(minn, maxn), 0, w - 1)
            c = self.generate_random_array(random.randint(minn, maxn), 0, h - 1)
            d = self.generate_random_array(random.randint(minn, maxn), 0, w - 1)
            s = ['' for _ in range(n)]
            alphas = 'crf'
            for j in range(n):
                s[j] = alphas[random.randint(0, 2)]
            s = ''.join(s)
            self.print_test(h, w, s, [a, b, c, d])
        self.generate_max_tests(10, 10, 100, 'crf')

    def print_test(self, h, w, s, data):
        self.test_number += 1
        print('Generating test %d' % self.test_number)
        
        test_name = '{0:0=2d}'.format(self.test_number)
        test_file = open(test_name, 'w')
        print(h, w, len(s), file=test_file)
        print(s, file=test_file)
        for element in data:
            if len(element) == 0:
                print(0, file=test_file)
            else:
                print(str(len(element)) + ' ' + ' '.join(str(e) for e in element), file=test_file)
        test_file.close()

    def generate_all_tests(self):
        self.generate_third_group_of_tests()

import time
start = time.time()
from sys import argv
if len(argv) >= 2:
    writer = TestGen(int(argv[1]))
else:
    writer = TestGen(0)
writer.generate_all_tests()
finish = time.time()
print('All tests were generated. Elapsed time: ', finish - start)
