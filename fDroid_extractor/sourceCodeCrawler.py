# -*- coding: utf-8 -*-
import os
import scrapy
import re
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
            version_obj={}
            url = xispas.xpath('p[@class="package-version-source"]//a/@href').get()
            version_id= xispas.xpath('div[@class="package-version-header"]//b/text()').get().encode('utf-8')
            version_date = xispas.xpath('div[@class="package-version-header"]//text()').extract()
            has_date = re.search(r'[0-9]{4}-[0-9]{2}-[0-9]{2}', str(''.join(version_date).encode('utf-8')).strip())
            if has_date:
                found = has_date.group(0)
                version_obj['date'] = found
            else:
                version_obj['date'] = "unknown"
            version_obj['id'] = version_id.decode('ascii', 'ignore').encode('ascii')
            version_obj['url'] = url.encode('utf-8','')
                #print("data = " + str(''.join(version_date).encode('utf-8')).strip())
            #header = xispas.xpath('header[@class="package-header"]')
            jso["versions"].append(version_obj)
            
        print( str(jso))
        return jso


