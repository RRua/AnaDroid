# -*- coding: utf-8 -*-
import os
import scrapy

class SourceCodeScrapper(scrapy.Spider):
    name = 'fdroid_source_code_crawler'

    def start_requests(self):
        url = ''
        tag = getattr(self, 'url', None)
        if tag is not None:
            url = tag
        yield scrapy.Request(url, self.parse)

    def parse(self, response):
        summary   = response.xpath('//div[@class="package-summary"]/text()').get()
        pack_name = response.xpath('//h3[@class="package-name"]/text()').get()
        icon_url  =  response.xpath('//img[@class="package-icon"]/@src').get()
        description = response.xpath('//div[@class="package-description"]//p/text()').get()
        all_sauce_code = response.xpath('//ul[@class="package-versions-list"]')
        jso = {}
        #jso["summary"] = summary.strip().replace("\'","").encode('utf-8','ignore')
        jso["icon_url"] = icon_url.encode('utf-8','ignore')
        jso["pack_name"] = pack_name.strip().replace("\'","").encode('utf-8','ignore')
        #jso["description"] = description.replace("\'","").encode('utf-8','ignore')
        jso["versions"] = []
        for xispas in all_sauce_code.xpath('li[@class="package-version"]'):
            url = xispas.xpath('p[@class="package-version-source"]//a/@href').get()
            #header = xispas.xpath('header[@class="package-header"]')
            jso["versions"].append(url.encode('utf-8'))
            
        print( str(jso))
        return jso


