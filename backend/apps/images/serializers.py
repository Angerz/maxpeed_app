from rest_framework import serializers


class ImageRefSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    url = serializers.CharField()
