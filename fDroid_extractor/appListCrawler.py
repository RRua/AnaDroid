# -*- coding: utf-8 -*-
import os
import scrapy

class AppListScrapper(scrapy.Spider):
    name = 'https://f-droid.org/'
    
    def start_requests(self):
        url=''
        tag = getattr(self, 'url', None)
        if tag is not None:
            url = tag
        yield scrapy.Request(url, self.parse)

    def parse(self, response):
        urls = response.xpath('//div[@id="full-package-list"]//a/@href').getall()
        jsdic={}
        jsdic[self.url]=urls[:30]
        newl = map( lambda l : l.encode('utf-8'),urls[:30])
        print( newl)
        return newl

