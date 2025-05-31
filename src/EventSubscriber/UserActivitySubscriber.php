<?php

namespace App\EventSubscriber;

use App\Entity\User;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Authentication\Token\Storage\TokenStorageInterface;



class UserActivitySubscriber implements EventSubscriberInterface
{
    private EntityManagerInterface $entityManager;

    private Security $security;


    public function __construct(Security $security, EntityManagerInterface $entityManager, TokenStorageInterface $tokenStorage)
    {
        $this->security = $security;
        $this->entityManager = $entityManager;
        $this->tokenStorage = $tokenStorage;
    }



    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::REQUEST => 'onKernelRequest',
        ];
    }

    public function onKernelRequest(RequestEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        // Предварительная проверка — есть ли токен вообще?
        $token = $this->security->getToken();
        if (!$token) {
            return;
        }

        $user = $token->getUser();
        dump($user);

        // Проверка на объект User и наличие ID
        if (!$user instanceof \App\Entity\User || null === $user->getId()) {
            $this->tokenStorage->setToken(null);
            return;
        }

        // Проверка: существует ли пользователь в базе
        $existingUser = $this->entityManager->getRepository(User::class)->find($user->getId());
        if (!$existingUser) {
            return;
        }

        // Обновляем lastSeen
        $existingUser->setLastSeen(new \DateTimeImmutable());

        try {
            $this->entityManager->flush();
        } catch (\Exception $e) {
            // можно логировать $e
        }
    }


}
